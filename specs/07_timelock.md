# Spec 07: TimeLock

Write a Solidity contract named `TimeLock`.
Use `pragma solidity ^0.8.24;`. Do not import any other files.

A savings vault: each user locks their own ETH until a time they choose, and can only take it out after that time.

## Required interface
- `function deposit(uint256 lockDuration) external payable`
- `function increaseLockTime(uint256 extraSeconds) external`
- `function withdraw() external`
- `function balanceOf(address user) external view returns (uint256)`
- `function unlockTime(address user) external view returns (uint256)`

## Behaviour
1. `deposit(lockDuration)` reverts if `msg.value` is 0. Otherwise it adds `msg.value` to the caller's balance, and the caller's unlock time becomes `block.timestamp + lockDuration`, unless the caller's current unlock time is later, in which case it stays the same. A deposit can never make the unlock time earlier.
2. `increaseLockTime(extraSeconds)` adds `extraSeconds` to the caller's unlock time. It reverts if the caller has no balance. It must never make the unlock time earlier, even for extremely large values of `extraSeconds`.
3. `withdraw()` sends the caller's whole balance to the caller and sets their balance to 0. It reverts if `block.timestamp < unlockTime(caller)` or if the caller's balance is 0.
4. Each user can only ever withdraw their own deposits.
