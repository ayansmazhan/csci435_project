# Spec 01: PiggyBank

Write a Solidity contract named `PiggyBank`.
Use `pragma solidity ^0.8.24;`. Do not import any other files.

## Required interface
- `function deposit() external payable`
- `function withdraw(uint256 amount) external`
- `function balanceOf(address user) external view returns (uint256)`

## Behaviour
1. `deposit()` adds `msg.value` to the caller's balance. It reverts if `msg.value` is 0.
2. `withdraw(amount)` sends `amount` wei to the caller and reduces their balance by `amount`. It reverts if `amount` is greater than the caller's balance.
3. `balanceOf(user)` returns the user's current balance.
4. A user can never withdraw ETH deposited by another user.
