// SPDX-License-Identifier: MIT
// Deliberately vulnerable control used to check that the attack test works. NOT a reference.
pragma solidity ^0.8.24;

contract Crowdfunding {
    address public immutable creator;
    uint256 public immutable goal;
    uint256 public immutable deadline;
    uint256 public totalRaised;
    bool public claimed;
    mapping(address => uint256) public contributions;

    constructor(uint256 goal_, uint256 duration) {
        require(goal_ > 0, "goal is zero");
        creator = msg.sender;
        goal = goal_;
        deadline = block.timestamp + duration;
    }

    function contribute() external payable {
        require(msg.value > 0, "zero contribution");
        require(block.timestamp < deadline, "campaign over");
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
    }

    function claim() external {
        require(msg.sender == creator, "only creator");
        require(block.timestamp >= deadline, "too early");
        require(totalRaised >= goal, "goal not reached");
        require(!claimed, "already claimed");
        claimed = true;                                  // effect before interaction
        (bool ok, ) = creator.call{value: totalRaised}("");
        require(ok, "payment failed");
    }

    function refund() external {
        require(block.timestamp >= deadline, "too early");
        require(totalRaised < goal, "goal was reached");
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "nothing to refund");
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "refund failed");
        contributions[msg.sender] = 0;   // VULNERABLE: state updated after the call
    }
}
