// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Auction {
    address public seller;
    uint256 public endTime;
    bool public ended;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) pendingReturns;

    constructor(uint256 _biddingTime) {
        // The deployer is the seller.
        // We assume msg.sender is the deployer unless it's a direct call without context, 
        // but standard constructor behavior implies msg.sender is the deployer.
        // However, to be explicit and safe against reentrancy or specific deploy patterns:
        // The spec says "The deployer is the seller."
        seller = msg.sender;
        
        // endTime is deployment timestamp + biddingTime
        endTime = block.timestamp + _biddingTime;
    }

    function seller() external view returns (address) {
        return seller;
    }

    function endTime() external view returns (uint256) {
        return endTime;
    }

    function highestBidder() external view returns (address) {
        return highestBidder;
    }

    function highestBid() external view returns (uint256) {
        return highestBid;
    }

    function pendingReturns(address bidder) external view returns (uint256) {
        return pendingReturns[bidder];
    }

    function ended() external view returns (bool) {
        return ended;
    }

    function bid() external payable {
        // Revert if auction has ended
        if (ended) {
            revert("Auction has ended");
        }

        // Revert if block.timestamp >= endTime
        if (block.timestamp >= endTime) {
            revert("Auction is closed");
        }

        // Revert if msg.value is not strictly greater than current highestBid
        uint256 currentHighest = (highestBidder == address(0)) ? 0 : highestBid;
        if (msg.value <= currentHighest) {
            revert("Bid must be strictly higher than the current highest bid");
        }

        // Update state
        pendingReturns[highestBidder] += currentHighest;
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        
        if (amount > 0) {
            payable(msg.sender).send(amount);
            pendingReturns[msg.sender] = 0;
        }
    }

    function end() external {
        // Revert if auction has already ended
        if (ended) {
            revert("Auction has already ended");
        }

        // Revert if block.timestamp < endTime
        if (block.timestamp < endTime) {
            revert("Auction is still running");
        }

        // Mark as ended and send highest bid to seller
        ended = true;
        
        if (highestBid > 0) {
            payable(seller).send(highestBid);
        }
    }
}
