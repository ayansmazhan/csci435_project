"""Turn data/results.csv (+ exploit_results.csv, meta files, reference rows) into the paper's
tables and figures. Every number in the paper should come from this script.

Run from the repo root (WSL, venv active), after run_all.py and exploit.py:
    python src/analyze.py
Writes figures/*.pdf + figures/*.png and tables/*.tex, and prints a summary.
"""
import csv
import json
import math
from collections import Counter, defaultdict
from pathlib import Path

import matplotlib
matplotlib.use("Agg")                      # draw to files, no window needed
import matplotlib.pyplot as plt

from pipeline import SPECS as PIPELINE_SPECS, evaluate

ROOT = Path(__file__).resolve().parent.parent
MODELS = ["qwen3.5:4b", "qwen2.5-coder:3b"]        # main experiment (the 7B runs are a pilot)
SPECS = ["01_piggybank", "02_token", "03_escrow", "04_voting",
         "05_auction", "06_crowdfunding", "07_timelock", "08_multisig"]
FIG, TAB = ROOT / "figures", ROOT / "tables"

# Outcome of one task (spec x model x seed), from worst to best. Each task gets exactly one.
OUTCOMES = ["Does not compile", "Wrong interface", "Fails some tests",
            "Passes tests, Slither H/M", "Passes tests, no Slither H/M"]
COLORS = ["#c0392b", "#e67e22", "#f1c40f", "#7fb3d5", "#1e8449"]


# ---------- loading ----------
def read_csv(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def load_tasks(csv_name="results.csv"):
    """{(spec, model, seed): {0: round-0 row, 1: repair row (if any)}} for the main models."""
    tasks = defaultdict(dict)
    if not (ROOT / "data" / csv_name).exists():
        return tasks
    for r in read_csv(ROOT / "data" / csv_name):
        if r["model"] in MODELS:
            tasks[(r["spec"], r["model"], r["seed"])][int(r["round"])] = r
    return tasks


def done_reason(row):
    meta = ROOT / row["file"].replace(".sol", "_meta.json")
    return json.loads(meta.read_text()).get("done_reason") if meta.exists() else None


# ---------- classification ----------
def outcome(row):
    if row["compiles"] != "True":
        return OUTCOMES[0]
    if row["tests_built"] != "True":
        return OUTCOMES[1]
    if row["all_tests_pass"] != "True":
        return OUTCOMES[2]
    if int(row["slither_high"] or 0) + int(row["slither_medium"] or 0) > 0:
        return OUTCOMES[3]
    return OUTCOMES[4]


def compile_error_category(row):
    """Group a failed compile into a failure mode (decided before looking at the counts)."""
    err = row["compile_error"]
    if done_reason(row) == "length":
        return "Output cut off (runaway text)"
    if "already declared" in err or "defined twice" in err:
        return "Name clash (state variable vs. function)"
    if "Undeclared identifier" in err:
        return "Undeclared / out-of-scope identifier"
    if any(k in err for k in ("payable", "pure", "view")):
        return "Wrong mutability (payable/pure/view)"
    if any(k in err for k in ("Invalid type", "operator", "Member")):
        return "Type error"
    return "Other"


# ---------- statistics ----------
def wilson(k, n, z=1.96):
    """95% Wilson confidence interval for a proportion k/n."""
    if n == 0:
        return (0.0, 0.0)
    p = k / n
    centre = (p + z * z / (2 * n)) / (1 + z * z / n)
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)
    return (max(0.0, centre - half), min(1.0, centre + half))


def fisher_two_sided(a, b, c, d):
    """Fisher's exact test p-value for the 2x2 table [[a, b], [c, d]]."""
    n1, n2, k = a + b, c + d, a + c

    def prob(x):
        return math.comb(n1, x) * math.comb(n2, k - x) / math.comb(n1 + n2, k)
    p_obs = prob(a)
    lo, hi = max(0, k - n2), min(k, n1)
    return min(1.0, sum(prob(x) for x in range(lo, hi + 1) if prob(x) <= p_obs * (1 + 1e-9)))


def pct(k, n):
    lo, hi = wilson(k, n)
    return f"{k}/{n} ({100 * k / n:.0f}\\%, {100 * lo:.0f}--{100 * hi:.0f})"


# ---------- main ----------
def main():
    FIG.mkdir(exist_ok=True)
    TAB.mkdir(exist_ok=True)
    tasks = load_tasks()
    exploit = {(r["spec"], r["model"], r["seed"]): r["exploitable"]
               for r in read_csv(ROOT / "data" / "exploit_results.csv")} \
        if (ROOT / "data" / "exploit_results.csv").exists() else {}

    # --- per-model summary (Table 1) ---
    summary = {}
    for m in MODELS:
        keys = [k for k in tasks if k[1] == m]
        r0 = [tasks[k][0] for k in keys]
        fin = [tasks[k].get(1, tasks[k][0]) for k in keys]
        n = len(keys)
        repaired = [k for k in keys if 1 in tasks[k]]
        s = {
            "n": n,
            "compile_r0": sum(r["compiles"] == "True" for r in r0),
            "compile_final": sum(r["compiles"] == "True" for r in fin),
            "repairs": len(repaired),
            "repairs_ok": sum(tasks[k][1]["compiles"] == "True" for k in repaired),
            "interface_ok": sum(r["tests_built"] == "True" for r in fin),
            "all_pass": sum(r["all_tests_pass"] == "True" for r in fin),
            "pass_clean": sum(outcome(r) == OUTCOMES[4] for r in fin),
            "pass_flagged": sum(outcome(r) == OUTCOMES[3] for r in fin),
            "exploitable": sum(exploit.get(k) == "True" for k in keys),
        }
        summary[m] = s

    rows_tex = [
        ("Compiles (first answer)", "compile_r0"),
        ("Compiles (after repair)", "compile_final"),
        ("Interface matches spec", "interface_ok"),
        ("Passes all tests", "all_pass"),
        ("Passes all tests, no Slither H/M", "pass_clean"),
    ]
    with open(TAB / "table_summary.tex", "w") as f:
        f.write("% Generated by src/analyze.py -- do not edit by hand\n")
        f.write("\\begin{tabular}{lrr}\n\\toprule\n")
        f.write("Measure (out of 24 tasks; 95\\% CI) & " + " & ".join(f"\\texttt{{{m}}}" for m in MODELS) + " \\\\\n\\midrule\n")
        for label, key in rows_tex:
            f.write(label + " & " + " & ".join(pct(summary[m][key], summary[m]["n"]) for m in MODELS) + " \\\\\n")
        f.write("Repairs that fixed compilation & " + " & ".join(
            f"{summary[m]['repairs_ok']}/{summary[m]['repairs']}" for m in MODELS) + " \\\\\n")
        f.write("Exploitable by re-entrancy attack & " + " & ".join(
            str(summary[m]["exploitable"]) for m in MODELS) + " \\\\\n")
        f.write("\\bottomrule\n\\end{tabular}\n")

    # --- failure modes of compile errors (Table 2): every failed attempt, by round ---
    modes = Counter()
    for k, rounds in tasks.items():
        for rnd, r in rounds.items():
            if r["compiles"] != "True":
                modes[(compile_error_category(r), k[1], rnd)] += 1
    categories = sorted({c for c, _, _ in modes}, key=lambda c: -sum(v for (cc, _, _), v in modes.items() if cc == c))
    with open(TAB / "table_compile_errors.tex", "w") as f:
        f.write("% Generated by src/analyze.py -- do not edit by hand\n")
        f.write("\\begin{tabular}{l" + "rr" * len(MODELS) + "}\n\\toprule\n")
        f.write(" & " + " & ".join(f"\\multicolumn{{2}}{{c}}{{\\texttt{{{m}}}}}" for m in MODELS) + " \\\\\n")
        f.write("Failure mode & " + " & ".join("first & repair" for _ in MODELS) + " \\\\\n\\midrule\n")
        for c in categories:
            f.write(c + " & " + " & ".join(f"{modes[(c, m, 0)]} & {modes[(c, m, 1)]}" for m in MODELS) + " \\\\\n")
        f.write("\\bottomrule\n\\end{tabular}\n")

    # --- reference baseline (Table 3): re-check every hand-written reference contract now ---
    print("Re-checking the reference contracts (tests + Slither)...", flush=True)
    ref = {spec: evaluate(ROOT / "reference" / f"{name}.sol", name) for spec, name in PIPELINE_SPECS.items()}
    with open(TAB / "table_reference.tex", "w") as f:
        f.write("% Generated by src/analyze.py -- do not edit by hand\n")
        f.write("\\begin{tabular}{lrrl}\n\\toprule\nSpec & Tests & Slither H/M & Slither detectors \\\\\n\\midrule\n")
        for s in SPECS:
            if s in ref:
                r = ref[s]
                f.write(f"{s.replace('_', chr(92) + '_')} & {r['tests_passed']}/{r['tests_total']} & "
                        f"{r['slither_high']}/{r['slither_medium']} & "
                        f"{r['slither_detectors'].replace('_', chr(92) + '_').replace(';', ', ') or '--'} \\\\\n")
        f.write("\\bottomrule\n\\end{tabular}\n")

    # --- Figure 1: outcome of every task, first answer vs after repair ---
    fig, ax = plt.subplots(figsize=(7, 2.8))
    labels, y = [], 0
    for m in MODELS:
        for rnd, rlabel in ((0, "first answer"), (1, "after repair")):
            counts = Counter(outcome(tasks[k].get(rnd, tasks[k][0]) if rnd else tasks[k][0])
                             for k in tasks if k[1] == m)
            left = 0
            for o, col in zip(OUTCOMES, COLORS):
                ax.barh(y, counts[o], left=left, color=col, edgecolor="white",
                        label=o if y == 0 else None)
                if counts[o]:
                    ax.text(left + counts[o] / 2, y, str(counts[o]), ha="center", va="center", fontsize=8)
                left += counts[o]
            labels.append(f"{m}\n{rlabel}")
            y += 1
    ax.set_yticks(range(len(labels)), labels, fontsize=8)
    ax.invert_yaxis()
    ax.set_xlabel("Tasks (8 specs x 3 seeds)")
    ax.set_xlim(0, 24)
    ax.legend(fontsize=7, ncol=3, loc="upper center", bbox_to_anchor=(0.5, -0.3), frameon=False)
    fig.tight_layout()
    for ext in ("pdf", "png"):
        fig.savefig(FIG / f"fig_outcomes.{ext}", dpi=200, bbox_inches="tight")
    plt.close(fig)

    # --- Figure 2: seeds (0-3) passing all tests after repair, per spec and model ---
    grid = [[sum(tasks[(s, m, str(seed))].get(1, tasks[(s, m, str(seed))][0])["all_tests_pass"] == "True"
                 for seed in (1, 2, 3) if (s, m, str(seed)) in tasks)
             for m in MODELS] for s in SPECS]
    fig, ax = plt.subplots(figsize=(4, 3.6))
    im = ax.imshow(grid, cmap="Greens", vmin=0, vmax=3, aspect="auto")
    ax.set_xticks(range(len(MODELS)), MODELS, fontsize=8)
    ax.set_yticks(range(len(SPECS)), [s.split("_", 1)[1] for s in SPECS], fontsize=8)
    for i, row in enumerate(grid):
        for j, v in enumerate(row):
            ax.text(j, i, f"{v}/3", ha="center", va="center", fontsize=8, color="white" if v >= 2 else "black")
    fig.colorbar(im, ax=ax, label="Seeds passing all tests", ticks=[0, 1, 2, 3])
    fig.tight_layout()
    for ext in ("pdf", "png"):
        fig.savefig(FIG / f"fig_spec_heatmap.{ext}", dpi=200, bbox_inches="tight")
    plt.close(fig)

    # --- follow-up experiment (Table 4): same prompts + one sentence about getters ---
    hint = load_tasks("results_hint.csv")
    if hint:
        def stats(tk, m):
            keys = [k for k in tk if k[1] == m]
            r0 = [tk[k][0] for k in keys]
            fin = [tk[k].get(1, tk[k][0]) for k in keys]
            clash = sum(r["compiles"] != "True" and compile_error_category(r).startswith("Name clash") for r in r0)
            return (len(keys), sum(r["compiles"] == "True" for r in r0), sum(r["compiles"] == "True" for r in fin),
                    sum(r["all_tests_pass"] == "True" for r in fin), clash)
        with open(TAB / "table_hint.tex", "w") as f:
            f.write("% Generated by src/analyze.py -- do not edit by hand\n")
            f.write("\\begin{tabular}{llrrrr}\n\\toprule\n")
            f.write("Model & Prompt & Compiles (first) & Compiles (repair) & Passes all tests & Name clashes (first) \\\\\n\\midrule\n")
            for m in MODELS:
                for label, tk in (("original", tasks), ("+ getter hint", hint)):
                    n, c0, cf, ap, cl = stats(tk, m)
                    f.write(f"\\texttt{{{m}}} & {label} & {c0}/{n} & {cf}/{n} & {ap}/{n} & {cl} \\\\\n")
            f.write("\\bottomrule\n\\end{tabular}\n")
        for m in MODELS:
            print("hint experiment", m, "original", stats(tasks, m), "hint", stats(hint, m),
                  "(n, compile first, compile repair, all tests pass, name clashes)")

    # --- printed summary (for the text of the paper) ---
    a, b = summary[MODELS[0]], summary[MODELS[1]]
    p = fisher_two_sided(a["compile_final"], a["n"] - a["compile_final"],
                         b["compile_final"], b["n"] - b["compile_final"])
    for m in MODELS:
        print(m, summary[m])
    print(f"Fisher exact test, compile-after-repair {MODELS[0]} vs {MODELS[1]}: p = {p:.3f}")
    print("Compile failure modes (mode, model, round): count")
    for k, v in sorted(modes.items(), key=lambda kv: -kv[1]):
        print("  ", k, v)
    print("Wrote", ", ".join(sorted(p.name for p in list(FIG.glob("fig_*")) + list(TAB.glob("table_*")))))


if __name__ == "__main__":
    main()
