"""Pipeline: plain-English spec -> local LLM -> Solidity -> compile -> tests -> Slither.

Run from the repo root, inside WSL, with the venv active:
    python src/pipeline.py --spec 01_piggybank --reference
    python src/pipeline.py --spec 01_piggybank --model qwen2.5-coder:7b --seed 1
"""
import argparse
import csv
import json
import re
import shutil
import subprocess
import tempfile
import time
from datetime import datetime
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parent.parent          # the repo folder
SPECS = {"01_piggybank": "PiggyBank"}                  # spec id -> contract name
OLLAMA_URL = "http://localhost:11434/api/generate"
TEMPERATURE = 0.7
RESULTS_CSV = ROOT / "data" / "results.csv"

PROMPT_TEMPLATE = """You are a Solidity developer. Implement the following specification.

{spec}

Return only the complete Solidity source code in a single ```solidity code block."""


# ---------- step 1: ask the model ----------
def generate(spec_text, model, seed):
    """Send the spec to Ollama. Returns (full answer text, seconds taken)."""
    body = {
        "model": model,
        "prompt": PROMPT_TEMPLATE.format(spec=spec_text),
        "stream": False,
        "keep_alive": "30m",
        "options": {"temperature": TEMPERATURE, "seed": seed, "num_ctx": 4096},
    }
    if model.startswith("qwen3"):            # "thinking" models: switch thinking off
        body["think"] = False
    start = time.time()
    r = requests.post(OLLAMA_URL, json=body, timeout=1800)
    r.raise_for_status()
    return r.json()["response"], time.time() - start


# ---------- step 2: pull the code out of the answer ----------
def extract_code(response):
    """Keep what is inside ```solidity ... ```; if there are no fences, keep everything."""
    m = re.search(r"```(?:solidity)?\s*\n(.*?)```", response, re.S)
    return m.group(1) if m else response


# ---------- step 3: does it compile on its own? ----------
def compile_check(sol_file):
    """Returns (compiled?, first error line or "")."""
    p = subprocess.run(["solc", str(sol_file)], capture_output=True, text=True)
    errors = [line for line in p.stderr.splitlines() if "Error" in line]
    return p.returncode == 0, (errors[0] if errors else "")


# ---------- step 4: does it pass the tests? ----------
def run_tests(sol_file, name):
    """Build a throw-away Foundry project with ONLY this contract and its test.
    Returns (test file compiled?, tests passed, tests total)."""
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        (work / "src").mkdir()
        (work / "test").mkdir()
        shutil.copy(ROOT / "foundry" / "foundry.toml", work)
        (work / "lib").symlink_to(ROOT / "foundry" / "lib")          # reuse forge-std
        shutil.copy(sol_file, work / "src" / f"{name}.sol")
        shutil.copy(ROOT / "foundry" / "test" / f"{name}.t.sol", work / "test")
        p = subprocess.run(["forge", "test", "--json"], cwd=work,
                           capture_output=True, text=True)
    try:
        suites = json.loads(p.stdout)
    except json.JSONDecodeError:
        # The test could not even be built, e.g. the contract has wrong function names.
        return False, 0, 0
    results = [t for suite in suites.values() for t in suite["test_results"].values()]
    passed = sum(t["status"] == "Success" for t in results)
    return True, passed, len(results)


# ---------- step 5: is it safe (according to Slither)? ----------
def run_slither(sol_file):
    """Returns (counts per impact level, list of detector names)."""
    p = subprocess.run(["slither", str(sol_file), "--json", "-"],
                       capture_output=True, text=True)
    counts = {"High": 0, "Medium": 0, "Low": 0, "Informational": 0, "Optimization": 0}
    detectors = []
    try:
        for d in json.loads(p.stdout)["results"].get("detectors", []):
            counts[d["impact"]] += 1
            detectors.append(d["check"])
    except (json.JSONDecodeError, KeyError):
        return None, []
    return counts, detectors


def evaluate(sol_file, name):
    """Run steps 3-5 on one .sol file and return the results as a dict."""
    compiles, error = compile_check(sol_file)
    if compiles:
        tests_built, passed, total = run_tests(sol_file, name)
        counts, detectors = run_slither(sol_file)
    else:
        tests_built, passed, total, counts, detectors = False, 0, 0, None, []
    counts = counts or {}
    return {
        "compiles": compiles,
        "compile_error": error,
        "tests_built": tests_built,
        "tests_passed": passed,
        "tests_total": total,
        "all_tests_pass": tests_built and total > 0 and passed == total,
        "slither_high": counts.get("High", ""),
        "slither_medium": counts.get("Medium", ""),
        "slither_low": counts.get("Low", ""),
        "slither_info": counts.get("Informational", ""),
        "slither_detectors": ";".join(sorted(set(detectors))),
    }


def save_row(row):
    """Append one result row to data/results.csv (writes the header the first time)."""
    RESULTS_CSV.parent.mkdir(parents=True, exist_ok=True)
    new_file = not RESULTS_CSV.exists()
    with open(RESULTS_CSV, "a", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(row))
        if new_file:
            writer.writeheader()
        writer.writerow(row)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec", required=True, choices=list(SPECS))
    ap.add_argument("--model", help="Ollama model name, e.g. qwen2.5-coder:7b")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--reference", action="store_true",
                    help="check the hand-written reference contract instead of asking a model")
    args = ap.parse_args()
    name = SPECS[args.spec]

    if args.reference:
        sol_file = ROOT / "reference" / f"{name}.sol"
        model, seed, temperature, seconds = "reference", "", "", 0.0
    else:
        if not args.model:
            ap.error("--model is required unless --reference is used")
        spec_text = (ROOT / "specs" / f"{args.spec}.md").read_text()
        print(f"Generating with {args.model} (seed {args.seed})... this can take a few minutes", flush=True)
        response, seconds = generate(spec_text, args.model, args.seed)
        out_dir = ROOT / "data" / "generated" / args.model.replace(":", "_") / args.spec
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / f"seed{args.seed}_raw.txt").write_text(response)   # keep the full answer
        sol_file = out_dir / f"seed{args.seed}.sol"
        sol_file.write_text(extract_code(response))
        model, seed, temperature = args.model, args.seed, TEMPERATURE

    row = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "spec": args.spec,
        "model": model,
        "seed": seed,
        "temperature": temperature,
        "gen_seconds": round(seconds, 1),
        **evaluate(sol_file, name),
        "file": str(sol_file.relative_to(ROOT)),
    }
    save_row(row)
    for key, value in row.items():
        print(f"{key:18} {value}")


if __name__ == "__main__":
    main()
