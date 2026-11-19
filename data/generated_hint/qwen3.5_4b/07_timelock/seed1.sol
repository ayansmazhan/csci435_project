// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TimeLock {
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public unlockTime;

    function deposit(uint256 lockDuration) external payable {
        require(msg.value > 0, "Deposit must have value");
        
        address caller = msg.sender;
        
        if (balanceOf[caller] == 0) {
            unlockTime[caller] = block.timestamp + lockDuration;
        } else {
            // Only update if the new time is later than the current one
            if (block.timestamp + lockDuration > unlockTime[caller]) {
                unlockTime[caller] = block.timestamp + lockDuration;
            }
        }
        
        balanceOf[caller] += msg.value;
    }

    function increaseLockTime(uint256 extraSeconds) external {
        address caller = msg.sender;
        
        require(balanceOf[caller] > 0, "Balance must be greater than 0");
        
        // Prevent unlock time from going back in time
        uint256 newUnlockTime = unlockTime[caller] + extraSeconds;
        require(newUnlockTime >= unlockTime[caller], "Unlock time cannot be decreased");
        
        unlockTime[caller] = newUnlockTime;
    }

    function withdraw() external {
        address caller = msg.sender;
        
        require(balanceOf[caller] > 0, "Balance must be greater than 0");
        require(block.timestamp >= unlockTime[caller], "Cannot withdraw before unlock time");
        
        (bool success,) = caller.call{value: balanceOf[caller]}("");
        require(success, "Transfer failed");
        
        balanceOf[caller] = 0;
    }

    function unlockTime(address user) external view returns (uint256) {
        return unlockTime[user];
    }
}
