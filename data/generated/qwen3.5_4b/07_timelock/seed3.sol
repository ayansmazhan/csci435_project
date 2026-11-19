// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TimeLock {
    mapping(address => uint256) balances;
    mapping(address => uint256) unlockTimes;

    function deposit(uint256 lockDuration) external payable {
        require(msg.value > 0, "Invalid amount");

        address caller = msg.sender;
        
        if (unlockTimes[caller] == 0) {
            unlockTimes[caller] = block.timestamp + lockDuration;
        } else {
            if (block.timestamp + lockDuration < unlockTimes[caller]) {
                revert("Lock time cannot be earlier");
            }
        }

        balances[caller] += msg.value;
    }

    function increaseLockTime(uint256 extraSeconds) external {
        require(balances[msg.sender] > 0, "No balance to lock");

        address caller = msg.sender;

        if (unlockTimes[caller] == 0) {
            unlockTimes[caller] = block.timestamp + extraSeconds;
        } else {
            // Ensure the new time is not earlier than current
            require(block.timestamp + extraSeconds >= unlockTimes[caller], "Lock time cannot be earlier");
            
            // Use a larger uint256 value to minimize risk of overflow with very large extraSeconds
            // However, since unlockTimes stores block.timestamp + seconds, and block.timestamp wraps around 
            // after ~10 years, we should rely on Solidity's safe arithmetic. 
            // The requirement says "must never make the unlock time earlier", implying safety even for large values.
            // In solidity ^0.8.24, addition is not implicit safe unless checked, but we added a check above.
            // We calculate the new time and ensure it's valid.
            
            uint256 potentialNewTime = block.timestamp + extraSeconds;
            if (potentialNewTime < unlockTimes[caller]) {
                revert("Lock time cannot be earlier");
            }
            unlockTimes[caller] = potentialNewTime;
        }
    }

    function withdraw() external {
        address caller = msg.sender;

        require(balances[caller] > 0, "No balance to withdraw");
        require(block.timestamp >= unlockTimes[caller], "Unlock time not reached");

        uint256 amount = balances[caller];
        balances[caller] = 0;
        
        (bool success, ) = caller.call{value: amount}(address(0));
        require(success, "Withdrawal failed");
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    function unlockTime(address user) external view returns (uint256) {
        return unlockTimes[user];
    }
}
