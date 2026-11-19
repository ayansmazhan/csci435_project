pragma solidity ^0.8.24;

contract Crowdfunding {
    address public _creator;
    uint256 public _goal;
    uint256 public _deadline;
    uint256 public _totalRaised;
    mapping(address => uint256) public _contributions;
    bool public _claimed;

    constructor(uint256 goal_, uint256 duration) {
        require(goal_ > 0, "Goal must be greater than 0");
        _creator = msg.sender;
        _goal = goal_;
        _deadline = block.timestamp + duration;
        _totalRaised = 0;
        _claimed = false;
    }

    function creator() external view returns (address) {
        return _creator;
    }

    function goal() external view returns (uint256) {
        return _goal;
    }

    function deadline() external view returns (uint256) {
        return _deadline;
    }

    function totalRaised() external view returns (uint256) {
        return _totalRaised;
    }

    function contributions(address contributor) external view returns (uint256) {
        return _contributions[contributor];
    }

    function claimed() external view returns (bool) {
        return _claimed;
    }

    function contribute() external payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        require(block.timestamp < _deadline, "Campaign has ended");
        _contributions[msg.sender] += msg.value;
        _totalRaised += msg.value;
    }

    function claim() external {
        require(msg.sender == _creator, "Only the creator can claim");
        require(block.timestamp >= _deadline, "Campaign has not ended");
        require(_totalRaised >= _goal, "Goal is not reached");
        require(!_claimed, "Campaign has already been claimed");
        payable(_creator).transfer(_totalRaised);
        _claimed = true;
    }

    function refund() external {
        require(block.timestamp >= _deadline, "Campaign has not ended");
        require(_totalRaised < _goal, "Goal is reached");
        require(_contributions[msg.sender] > 0, "No contribution to refund");
        uint256 amount = _contributions[msg.sender];
        _contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
