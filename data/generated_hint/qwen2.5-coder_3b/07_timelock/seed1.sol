pragma solidity ^0.8.24;

contract TimeLock {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public unlockTimes;

    event Deposit(address indexed user, uint256 amount, uint256 unlockTime);
    event IncreaseLockTime(address indexed user, uint256 extraSeconds);
    event Withdraw(address indexed user, uint256 amount);

    function deposit(uint256 lockDuration) external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        uint256 newUnlockTime = block.timestamp + lockDuration;
        if (unlockTimes[msg.sender] > newUnlockTime) {
            newUnlockTime = unlockTimes[msg.sender];
        }
        balances[msg.sender] += msg.value;
        unlockTimes[msg.sender] = newUnlockTime;
        emit Deposit(msg.sender, msg.value, newUnlockTime);
    }

    function increaseLockTime(uint256 extraSeconds) external {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(balances[msg.sender] > 0, "Sender has no balance");
        uint256 newUnlockTime = unlockTimes[msg.sender] + extraSeconds;
        if (newUnlockTime < block.timestamp) {
            newUnlockTime = block.timestamp;
        }
        unlockTimes[msg.sender] = newUnlockTime;
        emit IncreaseLockTime(msg.sender, extraSeconds);
    }

    function withdraw() external {
        require(block.timestamp >= unlockTimes[msg.sender], "Cannot withdraw yet");
        require(balances[msg.sender] > 0, "Sender has no balance");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        emit Withdraw(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    function unlockTime(address user) external view returns (uint256) {
        return unlockTimes[user];
    }
}
