# Spec 05: Auction

Write a Solidity contract named `Auction`.
Use `pragma solidity ^0.8.24;`. Do not import any other files.

An open auction for one item. Bidders send ETH; the highest bid wins and goes to the seller when the auction ends.
Outbid bidders get their ETH back by withdrawing it themselves.

## Required interface
- `constructor(uint256 biddingTime)`
- `function seller() external view returns (address)`
- `function endTime() external view returns (uint256)`
- `function highestBidder() external view returns (address)`
- `function highestBid() external view returns (uint256)`
- `function pendingReturns(address bidder) external view returns (uint256)`
- `function ended() external view returns (bool)`
- `function bid() external payable`
- `function withdraw() external`
- `function end() external`

## Behaviour
1. The deployer is the seller. `endTime()` is the deployment timestamp plus `biddingTime` seconds.
2. `bid()` reverts if `block.timestamp >= endTime()` or if `msg.value` is not strictly greater than the current `highestBid()` (so the first bid must be greater than 0). Otherwise the caller becomes the highest bidder with `msg.value`, and the previous highest bid is added to the previous highest bidder's `pendingReturns` (this also applies when the same address outbids itself). The previous bid is NOT sent back automatically.
3. `withdraw()` sends the caller's whole `pendingReturns` amount to the caller and sets it to 0. If the caller has nothing to withdraw, it does nothing and does not revert. The current highest bid can never be withdrawn.
4. `end()` can be called by anyone. It reverts if `block.timestamp < endTime()` or if the auction has already ended. Otherwise it marks the auction as ended and sends the highest bid to the seller (nothing is sent if there were no bids).
5. A bidder that cannot receive ETH (for example a contract that rejects payments) must not be able to stop other people from bidding.
