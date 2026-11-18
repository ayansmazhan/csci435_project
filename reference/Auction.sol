// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Auction {
    address public immutable seller;
    uint256 public immutable endTime;
    address public highestBidder;
    uint256 public highestBid;
    bool public ended;
    mapping(address => uint256) public pendingReturns;

    constructor(uint256 biddingTime) {
        seller = msg.sender;
        endTime = block.timestamp + biddingTime;
    }

    function bid() external payable {
        require(block.timestamp < endTime, "auction over");
        require(msg.value > highestBid, "bid too low");
        if (highestBidder != address(0)) {
            // Pull pattern: record the refund instead of sending it now.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) return;
        pendingReturns[msg.sender] = 0;                 // effect before interaction
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function end() external {
        require(block.timestamp >= endTime, "not yet");
        require(!ended, "already ended");
        ended = true;
        if (highestBid > 0) {
            (bool ok, ) = seller.call{value: highestBid}("");
            require(ok, "payment failed");
        }
    }
}
