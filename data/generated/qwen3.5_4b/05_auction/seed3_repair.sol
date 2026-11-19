// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Auction {
    address public seller;
    uint256 public endTime;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public pendingReturns;
    bool public ended;

    event BidPlaced(address indexed bidder, uint256 bidAmount);
    event AuctionEnded(uint256 endTime, uint256 highestBid);

    constructor(uint256 biddingTime) {
        seller = msg.sender;
        endTime = block.timestamp + biddingTime;
    }

    function bid() external payable {
        if (block.timestamp >= endTime) revert("Auction has ended");
        
        uint256 currentHighestBid = highestBid;
        
        if (msg.value <= currentHighestBid) revert("Bid must be strictly greater than the current highest bid");
        
        pendingReturns[highestBidder] += currentHighestBid;
        highestBid = msg.value;
        highestBidder = msg.sender;
        
        emit BidPlaced(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) return;
        
        payable(msg.sender).transfer(amount);
        pendingReturns[msg.sender] = 0;
    }

    function end() external {
        if (block.timestamp < endTime) revert("Auction has not ended");
        if (ended) revert("Auction has already ended");
        
        uint256 bidAmount = highestBid;
        payable(seller).transfer(bidAmount);
        ended = true;
        
        emit AuctionEnded(block.timestamp, bidAmount);
    }
}
