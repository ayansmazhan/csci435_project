# Spec 08: MultiSig

Write a Solidity contract named `MultiSig`.
Use `pragma solidity ^0.8.24;`. Do not import any other files.

A shared wallet with exactly three owners. Any owner can propose sending ETH, but the payment only happens after at least two different owners have confirmed it.

## Required interface
- `constructor(address owner1, address owner2, address owner3)`
- `receive() external payable`
- `function isOwner(address account) external view returns (bool)`
- `function transactionCount() external view returns (uint256)`
- `function submit(address to, uint256 value) external returns (uint256 txId)`
- `function confirm(uint256 txId) external`
- `function execute(uint256 txId) external`
- `function isConfirmed(uint256 txId, address owner) external view returns (bool)`
- `function getTransaction(uint256 txId) external view returns (address to, uint256 value, bool executed, uint256 numConfirmations)`

## Behaviour
1. The three constructor arguments are the owners. The constructor reverts if any of them is the zero address or if any two of them are the same address.
2. The contract accepts plain ETH transfers from anyone.
3. `submit(to, value)` can only be called by an owner. It stores a new transaction and returns its id. Ids start at 0 and increase by 1 for each new transaction; `transactionCount()` returns how many have been submitted. Submitting does NOT count as a confirmation.
4. `confirm(txId)` can only be called by an owner. It records that the caller confirms the transaction. It reverts if the transaction does not exist, has already been executed, or was already confirmed by the caller.
5. `execute(txId)` can only be called by an owner. It reverts if the transaction does not exist, has already been executed, or has fewer than 2 confirmations. Otherwise it marks the transaction as executed and sends `value` wei to `to`. If sending fails, `execute` reverts.
