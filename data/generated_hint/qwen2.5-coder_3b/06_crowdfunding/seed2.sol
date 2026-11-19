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
        totalRaised = 0;
        claimed = false;
    }

    function creator() external view returns (address) {
        return creator;
    }

    function goal() external view returns (uint256) {
        return goal;
    }

    function deadline() external view returns (uint256) {
        return deadline;
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

    function contribute() external payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        require(block.timestamp < deadline, "Campaign has ended");
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
    }

    function claim() external {
        require(msg.sender == creator, "Only the creator can claim");
        require(block.timestamp >= deadline, "Campaign has not ended");
        require(totalRaised >= goal, "Goal is not reached");
        require(!claimed, "Campaign has already been claimed");
        payable(creator).transfer(totalRaised);
        claimed = true;
    }

    function refund() external {
        require(block.timestamp >= deadline, "Campaign has not ended");
        require(totalRaised < goal, "Goal is reached");
        require(contributions[msg.sender] > 0, "No contribution to refund");
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
