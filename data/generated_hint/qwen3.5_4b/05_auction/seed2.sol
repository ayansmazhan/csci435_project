// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Auction {
    address public seller;
    uint256 public endTime;
    bool public ended;
    address private highestBidder;
    uint256 private highestBid;
    mapping(address => uint256) pendingReturns;

    constructor(uint256 _biddingTime) {
        // The deployer is the seller.
        seller = msg.sender;
        endTime = block.timestamp + _biddingTime;
    }

    function bid() external payable {
        require(block.timestamp < endTime, "Auction not yet ended");
        require(msg.value > highestBid, "Bid must be strictly greater than current highest bid");

        // Update highest bid and bidder
        highestBidder = msg.sender;
        highestBid = msg.value;

        // Add previous highest bid to the previous highest bidder's pendingReturns
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid - msg.value;
        }
    }

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            payable(msg.sender).transfer(amount);
            pendingReturns[msg.sender] = 0;
        }
    }

    function end() external {
        require(block.timestamp >= endTime, "Auction not yet ended");
        require(!ended, "Auction already ended");

        ended = true;

        // Send the highest bid to the seller if there is a bid
        if (highestBid > 0) {
            payable(seller).transfer(highestBid);
        }
    }
}
