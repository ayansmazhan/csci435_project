// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Crowdfunding {
    address public creator;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalRaised;
    mapping(address => uint256) public contributions;
    bool public claimed;

    constructor(uint256 goal_, uint256 duration_) {
        require(goal_ > 0, "Goal must be greater than zero");
        creator = msg.sender;
        goal = goal_;
        deadline = block.timestamp + duration_;
    }

    function contribute() external payable {
        require(msg.value > 0, "Contribution amount must be greater than zero");
        require(block.timestamp < deadline, "Campaign is closed");
        
        totalRaised += msg.value;
        contributions[msg.sender] += msg.value;
    }

    function claim() external {
        require(msg.sender == creator, "Only the creator can claim");
        require(block.timestamp >= deadline, "Campaign has not ended");
        require(totalRaised >= goal, "Goal not reached");
        require(!claimed, "Campaign already claimed");
        
        (bool success, ) = creator.call{value: totalRaised}("");
        require(success, "Transfer failed");
        
        claimed = true;
    }

    function refund() external {
        require(block.timestamp >= deadline, "Campaign has not ended");
        require(!goalReached(), "Goal has been reached");
        require(contributions[msg.sender] > 0, "No contribution to refund");
        
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund transfer failed");
    }

    function goalReached() internal view returns (bool) {
        return totalRaised >= goal;
    }
}
