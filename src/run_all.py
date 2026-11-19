"""Run the full experiment: every spec x model x seed.

Round 0 = the model's first answer.
Round 1 = one repair attempt, ONLY for contracts that did not compile:
          the model gets the spec, its own code and the solc error messages.

Results go to data/results.csv. The script can be stopped and restarted:
(spec, model, seed) combinations already in the CSV are skipped.

Run from the repo root, inside WSL, with the venv active:
    python src/run_all.py                                   # everything
    python src/run_all.py --specs 01_piggybank --models qwen3.5:4b --seeds 1   # a small test
"""
import argparse
import csv
import json
from datetime import datetime

from pipeline import (ROOT, SPECS, TEMPERATURE, PROMPT_TEMPLATE, generate,
                      extract_code, evaluate, compiler_output, save_row)

MODELS = ["qwen3.5:4b", "qwen2.5-coder:3b"]
SEEDS = [1, 2, 3]
RESULTS_CSV = ROOT / "data" / "results.csv"
GEN_DIR = ROOT / "data" / "generated"

# Follow-up experiment (--hint): one extra sentence about the most common compile error.
HINT = ("\n\nNote: in Solidity, a `public` state variable automatically creates a getter function "
        "with the same name. Never declare a function with the same name as a state variable.")

REPAIR_TEMPLATE = """You are a Solidity developer. You were asked to implement this specification:

{spec}

Your previous answer was:

```solidity
{code}
```

It does not compile with solc 0.8.24. The compiler output was:

{errors}

Fix the errors. Return only the complete corrected Solidity source code in a single ```solidity code block."""


def already_done():
    """(spec, model, seed) combinations whose round 0 is already in the CSV."""
    if not RESULTS_CSV.exists():
        return set()
    with open(RESULTS_CSV, newline="") as f:
        return {(r["spec"], r["model"], r["seed"]) for r in csv.DictReader(f) if r["round"] == "0"}


def warm_up(model):
    """Load the model into memory once, so loading time is not counted in gen_seconds."""
    print(f"Warming up {model} (loading it into memory)...", flush=True)
    _, seconds, _ = generate("Reply with OK.", model, 0)
    print(f"  loaded in {seconds:.0f} s")


def attempt(spec, model, seed, prompt, round_no):
    """Ask the model once, save its answer, evaluate it, append a row. Returns (row, .sol path)."""
    name = SPECS[spec]
    response, seconds, meta = generate(prompt, model, seed)
    out_dir = GEN_DIR / model.replace(":", "_") / spec
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = f"seed{seed}" + ("_repair" if round_no else "")
    (out_dir / f"{stem}_raw.txt").write_text(response)
    # Side file: why generation stopped ("stop" = finished, "length" = cut off) and how many tokens.
    (out_dir / f"{stem}_meta.json").write_text(json.dumps({
        "done_reason": meta.get("done_reason"),
        "output_tokens": meta.get("eval_count"),
        "prompt_tokens": meta.get("prompt_eval_count"),
    }, indent=2))
    sol_file = out_dir / f"{stem}.sol"
    sol_file.write_text(extract_code(response))
    row = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "spec": spec,
        "model": model,
        "seed": seed,
        "temperature": TEMPERATURE,
        "round": round_no,
        "gen_seconds": round(seconds, 1),
        **evaluate(sol_file, name),
        "file": str(sol_file.relative_to(ROOT)),
    }
    save_row(row, RESULTS_CSV)
    print(f"  round {round_no}: compiles={row['compiles']} "
          f"tests={row['tests_passed']}/{row['tests_total']} "
          f"slither H/M={row['slither_high']}/{row['slither_medium']} ({seconds:.0f} s, "
          f"{meta.get('eval_count')} tokens, {meta.get('done_reason')})", flush=True)
    return row, sol_file


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--specs", nargs="+", default=list(SPECS), choices=list(SPECS))
    ap.add_argument("--models", nargs="+", default=MODELS)
    ap.add_argument("--seeds", nargs="+", type=int, default=SEEDS)
    ap.add_argument("--hint", action="store_true",
                    help="follow-up experiment: add HINT to every prompt; results go to results_hint.csv")
    args = ap.parse_args()
    global RESULTS_CSV, GEN_DIR
    if args.hint:
        RESULTS_CSV = ROOT / "data" / "results_hint.csv"
        GEN_DIR = ROOT / "data" / "generated_hint"

    done = already_done()
    for model in args.models:
        warm_up(model)
        for spec in args.specs:
            spec_text = (ROOT / "specs" / f"{spec}.md").read_text() + (HINT if args.hint else "")
            for seed in args.seeds:
                if (spec, model, str(seed)) in done:
                    print(f"skip {spec} / {model} / seed {seed} (already in results.csv)")
                    continue
                print(f"{spec} / {model} / seed {seed}", flush=True)
                row, sol_file = attempt(spec, model, seed,
                                        PROMPT_TEMPLATE.format(spec=spec_text), 0)
                if not row["compiles"]:
                    repair_prompt = REPAIR_TEMPLATE.format(
                        spec=spec_text,
                        code=sol_file.read_text(),
                        errors=compiler_output(sol_file)[:3000])
                    attempt(spec, model, seed, repair_prompt, 1)


if __name__ == "__main__":
    main()
