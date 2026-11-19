"""Mutation testing: are the test suites strong enough to judge generated contracts?

Each mutant is a reference contract with ONE deliberate bug (a small text replacement).
A good test suite makes at least one test fail for every mutant ("killed").
A mutant that survives is either a gap in the tests or an "equivalent" mutant whose
behaviour is identical to the reference (e.g. a check that Solidity 0.8 already enforces).

Run from the repo root (WSL, venv active):
    python src/mutation.py
Writes tables/table_mutation.tex and data/mutation_results.csv.
"""
import csv
import tempfile
from pathlib import Path

from pipeline import ROOT, SPECS, compile_check, run_tests

# spec -> list of (description, text in reference, replacement)
MUTANTS = {
    "01_piggybank": [
        ("deposit of 0 allowed", '        require(msg.value > 0, "zero deposit");\n', ""),
        ("withdraw does not reduce balance", "        balances[msg.sender] -= amount;\n", ""),
        ("balance check removed (0.8 underflow still reverts)",
         '        require(amount <= balances[msg.sender], "insufficient balance");\n', ""),
    ],
    "02_token": [
        ("approve adds instead of replacing", "_allowances[msg.sender][spender] = amount;",
         "_allowances[msg.sender][spender] += amount;"),
        ("transferFrom does not reduce allowance", "        _allowances[from][msg.sender] -= amount;\n", ""),
        ("transfer to zero address allowed", '        require(to != address(0), "zero address");\n', ""),
        ("balance check removed (0.8 underflow still reverts)",
         '        require(_balances[from] >= amount, "balance too low");\n', ""),
    ],
    "03_escrow": [
        ("anyone can release", "require(msg.sender == buyer || msg.sender == arbiter", "require(true"),
        ("release possible twice", '        require(!settled, "already settled");\n        settled = true;\n        (bool ok, ) = seller',
         "        settled = true;\n        (bool ok, ) = seller"),
        ("accepts plain ETH", "    // No receive()", "    receive() external payable {}\n    // No receive()"),
        ("buyer can also refund", "require(msg.sender == seller || msg.sender == arbiter",
         "require(msg.sender == seller || msg.sender == arbiter || msg.sender == buyer"),
    ],
    "04_voting": [
        ("anyone can give the right to vote", '        require(msg.sender == chairperson, "only chairperson");\n', ""),
        ("double voting allowed", '        require(!_hasVoted[msg.sender], "already voted");\n', ""),
        ("tie goes to the higher number", "_votes[i] > _votes[winner]", "_votes[i] >= _votes[winner]"),
        ("chairperson votes automatically", "        _votes = new uint256[](numProposals);",
         "        _votes = new uint256[](numProposals);\n        _canVote[msg.sender] = true;"),
        ("giving the right twice allowed", '        require(!_canVote[voter], "already has the right");\n', ""),
    ],
    "05_auction": [
        ("refunds pushed immediately (DoS-prone)", "pendingReturns[highestBidder] += highestBid;",
         '(bool s, ) = highestBidder.call{value: highestBid}(""); require(s);'),
        ("outbidding yourself not recorded", "if (highestBidder != address(0)) {",
         "if (highestBidder != address(0) && highestBidder != msg.sender) {"),
        ("end() can run twice", '        require(!ended, "already ended");\n', ""),
        ("withdraw reverts when nothing to withdraw", "if (amount == 0) return;", 'require(amount > 0, "nothing");'),
        ("bidding allowed at endTime", "require(block.timestamp < endTime", "require(block.timestamp <= endTime"),
        ("pending returns overwritten", "pendingReturns[highestBidder] += highestBid;",
         "pendingReturns[highestBidder] = highestBid;"),
    ],
    "06_crowdfunding": [
        ("goal needs strictly more", "totalRaised >= goal", "totalRaised > goal"),
        ("anyone can claim", '        require(msg.sender == creator, "only creator");\n', ""),
        ("refund does not reset contribution", "        contributions[msg.sender] = 0;                   // effect before interaction\n", ""),
        ("claim before deadline", 'require(block.timestamp >= deadline, "too early");\n        require(totalRaised >= goal',
         "require(totalRaised >= goal"),
        ("contribution allowed at deadline", "require(block.timestamp < deadline", "require(block.timestamp <= deadline"),
        ("claim possible twice", "        claimed = true;                                  // effect before interaction\n", ""),
        ("totalRaised decreases on refund", "        contributions[msg.sender] = 0;                   // effect before interaction\n",
         "        contributions[msg.sender] = 0;\n        totalRaised -= amount;\n"),
    ],
    "07_timelock": [
        ("unchecked addition (overflow attack)", "        _unlockTimes[msg.sender] += extraSeconds;",
         "        unchecked { _unlockTimes[msg.sender] += extraSeconds; }"),
        ("deposit can shorten the lock", "        if (newUnlock > _unlockTimes[msg.sender]) {\n            _unlockTimes[msg.sender] = newUnlock;   // only ever move the time later\n        }",
         "        _unlockTimes[msg.sender] = newUnlock;"),
        ("withdraw at unlock time blocked", "require(block.timestamp >= _unlockTimes[msg.sender]",
         "require(block.timestamp > _unlockTimes[msg.sender]"),
        ("balance not reset after withdraw", "        _balances[msg.sender] = 0;                     // effect before interaction\n", ""),
        ("increaseLockTime without balance", '        require(_balances[msg.sender] > 0, "nothing locked");\n', ""),
        ("withdraw of 0 does not revert", '        require(amount > 0, "nothing to withdraw");\n', ""),
    ],
    "08_multisig": [
        ("strangers can submit", "external onlyOwner returns (uint256 txId)", "external returns (uint256 txId)"),
        ("owner can confirm twice", '        require(!isConfirmed[txId][msg.sender], "already confirmed");\n', ""),
        ("one confirmation is enough", "require(t.numConfirmations >= REQUIRED", "require(t.numConfirmations >= 1"),
        ("execute possible twice", '        require(!t.executed, "already executed");\n', ""),
        ("duplicate owners allowed",
         '        require(owner1 != owner2 && owner1 != owner3 && owner2 != owner3, "duplicate owner");\n', ""),
        ("failed payment ignored", '        (bool ok, ) = t.to.call{value: t.value}("");\n        require(ok, "payment failed");',
         '        (bool ok, ) = t.to.call{value: t.value}("");\n        ok;'),
        ("submitting auto-confirms", "numConfirmations: 0}));",
         "numConfirmations: 1}));\n        isConfirmed[txId][msg.sender] = true;"),
        ("strangers can execute", "function execute(uint256 txId) external onlyOwner txExists",
         "function execute(uint256 txId) external txExists"),
    ],
}


def main():
    out = []
    for spec, mutants in MUTANTS.items():
        name = SPECS[spec]
        original = (ROOT / "reference" / f"{name}.sol").read_text()
        for description, old, new in mutants:
            if original.count(old) != 1:
                raise SystemExit(f"{spec}: mutant '{description}' does not match the reference exactly once")
            with tempfile.TemporaryDirectory() as tmp:
                sol = Path(tmp) / f"{name}.sol"
                sol.write_text(original.replace(old, new))
                compiles, _ = compile_check(sol)
                built, passed, total = run_tests(sol, name) if compiles else (False, 0, 0)
            killed = (not compiles) or (not built) or passed < total
            print(f"{spec:16} {'KILLED  ' if killed else 'SURVIVED'} {passed}/{total}  {description}")
            out.append({"spec": spec, "mutant": description, "tests_passed": passed,
                        "tests_total": total, "killed": killed})

    with open(ROOT / "data" / "mutation_results.csv", "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(out[0]))
        writer.writeheader()
        writer.writerows(out)

    (ROOT / "tables").mkdir(exist_ok=True)
    with open(ROOT / "tables" / "table_mutation.tex", "w") as f:
        f.write("% Generated by src/mutation.py -- do not edit by hand\n")
        f.write("\\begin{tabular}{lrrr}\n\\toprule\nSpec & Tests & Mutants & Killed \\\\\n\\midrule\n")
        for spec in MUTANTS:
            rows = [r for r in out if r["spec"] == spec]
            f.write(f"{spec.replace('_', chr(92) + '_')} & {rows[0]['tests_total']} & {len(rows)} & "
                    f"{sum(r['killed'] for r in rows)} \\\\\n")
        f.write(f"\\midrule\nTotal & & {len(out)} & {sum(r['killed'] for r in out)} \\\\\n")
        f.write("\\bottomrule\n\\end{tabular}\n")
    survived = [r for r in out if not r["killed"]]
    print(f"\n{len(out) - len(survived)}/{len(out)} mutants killed. Survivors:",
          "; ".join(f"{r['spec']}: {r['mutant']}" for r in survived) or "none")


if __name__ == "__main__":
    main()
