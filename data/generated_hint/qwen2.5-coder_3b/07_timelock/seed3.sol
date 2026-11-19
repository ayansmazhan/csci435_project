pragma solidity ^0.8.24;

contract TimeLock {
    mapping(address => uint256) private balances;
    mapping(address => uint256) private unlockTimes;

    event Deposit(address indexed user, uint256 amount, uint256 lockDuration);
    event IncreaseLockTime(address indexed user, uint256 extraSeconds);
    event Withdraw(address indexed user, uint256 amount);

    function deposit(uint256 lockDuration) public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        balances[msg.sender] += msg.value;
        unlockTimes[msg.sender] = block.timestamp + lockDuration;

        emit Deposit(msg.sender, msg.value, lockDuration);
    }

    function increaseLockTime(uint256 extraSeconds) public {
        require(balances[msg.sender] > 0, "No balance to increase lock time");

        unlockTimes[msg.sender] += extraSeconds;

        emit IncreaseLockTime(msg.sender, extraSeconds);
    }

    function withdraw() public {
        require(block.timestamp >= unlockTimes[msg.sender], "Cannot withdraw before unlock time");
        require(balances[msg.sender] > 0, "No balance to withdraw");

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function balanceOf(address user) public view returns (uint256) {
        return balances[user];
    }

    function unlockTime(address user) public view returns (uint256) {
        return unlockTimes[user];
    }
}
