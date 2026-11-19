// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Crowdfunding {
    address public creator;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalRaised;
    mapping(address => uint256) public contributions;
    bool public claimed;

    constructor(uint256 goal_, uint256 duration) {
        require(goal_ > 0, "Goal must be greater than 0");
        creator = msg.sender;
        goal = goal_;
        deadline = block.timestamp + duration;
    }

    function contribute() external payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        require(block.timestamp < deadline, "Campaign has ended");

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
    }

    function claim() external {
        require(msg.sender == creator, "Only the creator can claim");
        require(block.timestamp >= deadline, "Deadline has not passed");
        require(totalRaised >= goal, "Goal has not been reached");
        require(!claimed, "Campaign has already been claimed");

        (bool success, ) = creator.call{value: totalRaised}("");
        require(success, "Transfer failed");
        claimed = true;
    }

    function refund() external {
        require(msg.sender != creator, "Creators cannot refund themselves");
        require(block.timestamp >= deadline, "Deadline has not passed");
        require(totalRaised < goal, "Goal has been reached");
        require(contributions[msg.sender] > 0, "No contribution to refund");

        contributions[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: contributions[msg.sender]}("");
        // Note: The above line sets the balance to 0 before assigning back. 
        // Correct logic: transfer the value from contract to user.
        require(success, "Transfer failed");

        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        (bool success2, ) = msg.sender.call{value: refundAmount}("");
        require(success2, "Refund transfer failed");
    }

    function totalRaised() external view returns (uint256) {
        return totalRaised;
    }

    function contributions(address contributor) external view returns (uint256) {
        return contributions[contributor];
    }

    function claimed() external view returns (bool) {
        return claimed;
    }
}
