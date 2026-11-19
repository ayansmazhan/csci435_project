pragma solidity ^0.8.24;

contract Crowdfunding {
    address public _creator;
    uint256 public _goal;
    uint256 public _deadline;
    uint256 public _totalRaised;
    mapping(address => uint256) public _contributions;
    bool public _claimed;

    constructor(uint256 goal_, uint256 duration_) {
        require(goal_ > 0, "Goal must be greater than zero");
        _creator = msg.sender;
        _deadline = block.timestamp + duration_;
        _goal = goal_;
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
        require(msg.value > 0, "Contributions must be greater than zero");
        require(block.timestamp < _deadline(), "Cannot contribute after deadline");

        _contributions[msg.sender] += msg.value;
        _totalRaised += msg.value;
    }

    function claim() external {
        require(msg.sender == _creator, "Only the creator can claim the funds");
        require(block.timestamp >= _deadline(), "Cannot claim funds before deadline");
        require(_goal >= _totalRaised, "Goal must be reached to claim funds");
        require(!_claimed, "Funds have already been claimed");

        (bool success, ) = payable(_creator).call{value: _totalRaised}("");
        require(success, "Failed to claim funds");

        _claimed = true;
    }

    function refund() external {
        require(block.timestamp >= _deadline(), "Cannot refund funds before deadline");
        require(_goal < _totalRaised, "Goal must not be reached to refund funds");
        require(_contributions[msg.sender] > 0, "No contribution to refund");

        uint256 refundAmount = _contributions[msg.sender];
        _contributions[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
    }
}
