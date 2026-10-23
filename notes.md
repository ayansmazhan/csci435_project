CSCI 435 Research track, Scoping Note, "Natural-language to smart contract with a LMM"
1. What will I build and measure?
-I prompt the chosen LLM to create a smart contract written with Solidity. After which, that code will be compiled with solc version 0.8.24. and run through some Foundry tests. Finally, it will be scanned with Slither.
-20 specs: 5 contract types of 4 variants will be used. Each spec states the exact function signaturs, so tests can check correctness.
-Two models: qwen2.5-coder:7b and qwen3.5:4b will be used and run locally through Ollama.
-One comparison: generation alone vs one repair round in which the compiler errors are sent back to the model.
-Three measures: compiles/passes all tests/ has no Slither high or medium findings. Plus a manual safety review of a sample, and every failure sorted into categories.
2. What data and tools will I use, and can I actually get them?
-No on-chain data and no testnet needed. Everything run locally, and all tools are free.
-Already shown to work:One generation took about 1,5 minutes on an 8 GB laptop. It compiled, and slither ran on it.
-The run count: 20 specs * 3 samples * 2 models is about 120 generations, a few hours per full run.
3. What will the results look like if things go well?
-Main fiugre: a bar chart of the compile/ test-pass/ Slither-clean rates for each model, with and without repair.
-A table of failure types with counts.
-A manual review of code after the pipeline.
spec01 / qwen2.5-coder:7b / seed1: SAFE (balance updated before transfer).
Correct per tests (5/5). Deviations: extra require(amount > 0) in withdraw
(not in spec, not tested); public `balances` getter; no SPDX line; uses transfer. 
spec01 / qwen3.5:4b / seed1: correct (5/5). Slither HIGH reentrancy-eth.
Manual: call before balance update (unsafe pattern). Attack test: NOT exploitable,
because the 0.8 underflow check reverts the reentrant withdrawal. A version
with `balances = 0` instead of `-=` WOULD be drained.
