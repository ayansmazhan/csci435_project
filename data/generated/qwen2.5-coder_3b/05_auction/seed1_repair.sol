pragma solidity ^0.8.24;

contract Auction {
    address public seller;
    uint256 public endTime;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public pendingReturns;

    constructor(uint256 biddingTime) {
        seller = msg.sender;
        endTime = block.timestamp + biddingTime;
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
        return block.timestamp >= endTime;
    }

    function bid() external payable {
        require(block.timestamp < endTime, "Auction has ended");
        require(msg.value > highestBid, "Bid must be greater than the current highest bid");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdraw() external {
        require(pendingReturns[msg.sender] > 0, "No pending returns to withdraw");
        uint256 amount = pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function end() external {
        require(block.timestamp >= endTime, "Auction has not ended");
        require(!ended(), "Auction has already ended");

        payable(seller).transfer(highestBid);
        highestBidder = address(0);
        highestBid = 0;
    }
}
