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
        deadline = block.timestamp + duration_;
        goal = goal_;
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
        require(msg.value > 0, "Contributions must be greater than zero");
        require(block.timestamp < deadline(), "Cannot contribute after deadline");

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
    }

    function claim() external {
        require(msg.sender == creator, "Only the creator can claim the funds");
        require(block.timestamp >= deadline(), "Cannot claim funds before deadline");
        require(goal >= totalRaised, "Goal must be reached to claim funds");
        require(!claimed, "Funds have already been claimed");

        (bool success, ) = payable(creator).call{value: totalRaised}("");
        require(success, "Failed to claim funds");

        claimed = true;
    }

    function refund() external {
        require(block.timestamp >= deadline(), "Cannot refund funds before deadline");
        require(goal < totalRaised, "Goal must not be reached to refund funds");
        require(contributions[msg.sender] > 0, "No contribution to refund");

        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
    }
}
