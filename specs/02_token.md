# Spec 02: SimpleToken

Write a Solidity contract named `SimpleToken`.
Use `pragma solidity ^0.8.24;`. Do not import any other files.

## Required interface
- `constructor(uint256 initialSupply)`
- `function totalSupply() external view returns (uint256)`
- `function balanceOf(address account) external view returns (uint256)`
- `function transfer(address to, uint256 amount) external returns (bool)`
- `function approve(address spender, uint256 amount) external returns (bool)`
- `function allowance(address owner, address spender) external view returns (uint256)`
- `function transferFrom(address from, address to, uint256 amount) external returns (bool)`
- `event Transfer(address indexed from, address indexed to, uint256 value)`
- `event Approval(address indexed owner, address indexed spender, uint256 value)`

## Behaviour
1. The constructor gives all `initialSupply` tokens to the deployer. `totalSupply()` returns `initialSupply`.
2. `transfer(to, amount)` moves `amount` tokens from the caller to `to`, emits `Transfer(caller, to, amount)` and returns `true`. It reverts if the caller's balance is less than `amount` or if `to` is the zero address. Transferring 0 tokens is allowed.
3. `approve(spender, amount)` sets the caller's allowance for `spender` to exactly `amount` (replacing any previous value), emits `Approval(caller, spender, amount)` and returns `true`.
4. `transferFrom(from, to, amount)` moves `amount` tokens from `from` to `to` on behalf of the caller. It reverts if the allowance of `from` for the caller is less than `amount`, if `from`'s balance is less than `amount`, or if `to` is the zero address. On success it reduces that allowance by `amount`, emits `Transfer(from, to, amount)` and returns `true`.
5. No function may create or destroy tokens: `totalSupply()` never changes after deployment.
