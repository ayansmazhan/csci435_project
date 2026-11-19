pragma solidity ^0.8.24;

contract TimeLock {
    // Mapping from user addresses to their unlock times
    mapping(address => uint256) public unlockTimes;

    // Mapping from user addresses to their balances
    mapping(address => uint256) public balances;

    // Event emitted when a deposit is made
    event Deposit(address indexed user, uint256 lockDuration, uint256 depositAmount);

    // Event emitted when the lock time is increased
    event IncreaseLockTime(address indexed user, uint256 extraSeconds);

    // Event emitted when a withdrawal is made
    event Withdrawal(address indexed user, uint256 amount);

    // Function to deposit ETH into the vault
    function deposit(uint256 lockDuration) external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        unlockTimes[msg.sender] = block.timestamp + lockDuration;
        emit Deposit(msg.sender, lockDuration, msg.value);
    }

    // Function to increase the lock time
    function increaseLockTime(uint256 extraSeconds) external {
        require(balances[msg.sender] > 0, "No balance to increase lock time");
        unlockTimes[msg.sender] += extraSeconds;
        emit IncreaseLockTime(msg.sender, extraSeconds);
    }

    // Function to withdraw ETH from the vault
    function withdraw() external {
        require(block.timestamp >= unlockTimes[msg.sender], "Cannot withdraw before unlock time");
        require(balances[msg.sender] > 0, "No balance to withdraw");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    // Function to get the balance of a user
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    // Function to get the unlock time of a user
    function unlockTime(address user) external view returns (uint256) {
        return unlockTimes[user];
    }
}
