# Spec 03: Escrow

Write a Solidity contract named `Escrow`.
Use `pragma solidity ^0.8.24;`. Do not import any other files.

The contract holds a payment from a buyer until the deal is settled.
A trusted arbiter can settle the deal in either direction if the buyer and seller disagree.

## Required interface
- `constructor(address seller_, address arbiter_) payable`
- `function buyer() external view returns (address)`
- `function seller() external view returns (address)`
- `function arbiter() external view returns (address)`
- `function settled() external view returns (bool)`
- `function release() external`
- `function refund() external`

## Behaviour
1. The deployer is the buyer. The ETH sent with deployment is the escrowed amount. The constructor reverts if no ETH is sent, or if `seller_` or `arbiter_` is the zero address.
2. `release()` sends the whole escrowed amount to the seller and marks the escrow as settled. Only the buyer or the arbiter may call it.
3. `refund()` sends the whole escrowed amount back to the buyer and marks the escrow as settled. Only the seller or the arbiter may call it.
4. Once settled, both `release()` and `refund()` revert. `settled()` returns `true` after settlement and `false` before.
5. The contract does not accept any ETH after deployment: a plain ETH transfer to it must revert.
