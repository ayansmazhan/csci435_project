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
        require(goal_ > 0, "Goal must be greater than 0");
        creator = msg.sender;
        goal = goal_;
        deadline = block.timestamp + duration_;
    }

    function contribute() external payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        require(block.timestamp < deadline, "Campaign is over");
        
        totalRaised += msg.value;
        contributions[msg.sender] += msg.value;
    }

    function claim() external {
        require(msg.sender == creator, "Only creator can claim");
        require(block.timestamp >= deadline, "Deadline has not passed");
        require(totalRaised >= goal, "Goal not reached");
        require(!claimed, "Campaign already claimed");
        
        (bool success, ) = creator.call{value: totalRaised}("");
        require(success, "Failed to transfer funds to creator");
        claimed = true;
    }

    function refund() external {
        require(block.timestamp >= deadline, "Deadline has not passed");
        require(totalRaised < goal, "Goal has been reached");
        require(contributions[msg.sender] > 0, "No contributions to refund");
        
        (bool success, ) = msg.sender.call{value: contributions[msg.sender]}("");
        require(success, "Failed to transfer funds back to contributor");
        
        contributions[msg.sender] = 0;
    }

    function totalRaised() external view returns (uint256) {
        return totalRaised;
    }
}
