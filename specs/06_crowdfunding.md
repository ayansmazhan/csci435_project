# Spec 06: Crowdfunding

Write a Solidity contract named `Crowdfunding`.
Use `pragma solidity ^0.8.24;`. Do not import any other files.

A creator raises ETH towards a goal before a deadline. If the goal is reached, the creator takes the money.
If it is not reached, every contributor can take their own contribution back.

## Required interface
- `constructor(uint256 goal_, uint256 duration)`
- `function creator() external view returns (address)`
- `function goal() external view returns (uint256)`
- `function deadline() external view returns (uint256)`
- `function totalRaised() external view returns (uint256)`
- `function contributions(address contributor) external view returns (uint256)`
- `function claimed() external view returns (bool)`
- `function contribute() external payable`
- `function claim() external`
- `function refund() external`

## Behaviour
1. The deployer is the creator. `deadline()` is the deployment timestamp plus `duration` seconds. The constructor reverts if `goal_` is 0.
2. `contribute()` adds `msg.value` to the caller's contribution and to `totalRaised()`. It reverts if `msg.value` is 0 or if `block.timestamp >= deadline()`. Contributions are still accepted after the goal is reached, as long as the deadline has not passed.
3. The goal counts as reached when `totalRaised() >= goal()`.
4. `claim()` sends the whole raised amount to the creator and marks the campaign as claimed. It reverts unless ALL of these hold: the caller is the creator, `block.timestamp >= deadline()`, the goal is reached, and it has not been claimed before.
5. `refund()` sends the caller's whole contribution back to them and sets their contribution to 0. It reverts unless ALL of these hold: `block.timestamp >= deadline()`, the goal is NOT reached, and the caller's contribution is greater than 0.
6. `totalRaised()` is the total ever contributed: it does not decrease when refunds are paid.
