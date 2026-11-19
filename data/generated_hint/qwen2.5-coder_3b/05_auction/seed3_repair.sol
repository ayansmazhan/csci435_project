pragma solidity ^0.8.24;

contract Auction {
    address public seller;
    uint256 public biddingEndTime;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public pendingReturns;

    constructor(uint256 _biddingTime) {
        seller = msg.sender;
        biddingEndTime = block.timestamp + _biddingTime;
    }

    function seller() external view returns (address) {
        return seller;
    }

    function biddingEndTime() external view returns (uint256) {
        return biddingEndTime;
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
        return block.timestamp >= biddingEndTime;
    }

    function bid() external payable {
        require(block.timestamp < biddingEndTime, "Auction has ended");
        require(msg.value > highestBid, "Bid must be greater than the current highest bid");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdraw() external {
        require(pendingReturns[msg.sender] > 0, "No pending returns");
        uint256 amount = pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function end() external {
        require(block.timestamp >= biddingEndTime, "Auction has not ended");
        require(highestBidder != address(0), "No bids");

        payable(seller).transfer(highestBid);
    }
}
