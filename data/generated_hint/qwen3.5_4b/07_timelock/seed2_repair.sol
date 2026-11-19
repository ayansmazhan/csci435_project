// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TimeLock {
    mapping(address => uint256) internal balances;
    mapping(address => uint256) internal unlockTimes;

    function deposit(uint256 lockDuration) external payable {
        require(msg.value > 0, "Deposit must have a value");

        address caller = msg.sender;
        
        // If the new calculated time is earlier than current, revert (not allowed to go back)
        uint256 proposedUnlockTime = block.timestamp + lockDuration;
        if (proposedUnlockTime < unlockTimes[caller]) {
            revert("Cannot set unlock time in the past");
        }

        balances[caller] += msg.value;
        unlockTimes[caller] = proposedUnlockTime;
    }

    function increaseLockTime(uint256 extraSeconds) external {
        require(balances[msg.sender] > 0, "No balance to extend lock");

        address caller = msg.sender;
        uint256 currentUnlockTime = unlockTimes[caller];
        
        // Ensure the new time is never earlier than the current one.
        // Since extraSeconds is uint256, it is always >= 0, so adding it will never decrease the value.
        // However, we explicitly check to satisfy the spec requirement for clarity and safety.
        require(currentUnlockTime + extraSeconds >= currentUnlockTime, "Lock time cannot be decreased");

        unlockTimes[caller] = currentUnlockTime + extraSeconds;
    }

    function withdraw() external {
        address caller = msg.sender;
        
        uint256 currentTime = block.timestamp;
        uint256 requiredTime = unlockTimes[caller];
        
        require(currentTime >= requiredTime, "Withdrawal time has not arrived");
        require(balances[caller] > 0, "No balance to withdraw");

        // Transfer the entire balance to the caller
        payable(caller).transfer(balances[caller]);
        
        // Set balance to 0 after transfer
        balances[caller] = 0;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    function unlockTime(address user) external view returns (uint256) {
        return unlockTimes[user];
    }
}
