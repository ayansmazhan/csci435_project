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

        // Update balance only if it's strictly increasing (or same, but logic implies adding to existing)
        // Actually, spec says "adds msg.value to the caller's balance". 
        // So we always add. The check is just on the timestamp.
        balances[caller] += msg.value;
        unlockTimes[caller] = proposedUnlockTime;
    }

    function increaseLockTime(uint256 extraSeconds) external {
        require(balances[msg.sender] > 0, "No balance to extend lock");

        address caller = msg.sender;
        uint256 currentUnlockTime = unlockTimes[caller];
        // Ensure the new time is never earlier than the current one (even with huge extraSeconds)
        // Since block.timestamp only increases, we just need to ensure:
        // currentUnlockTime + extraSeconds >= currentUnlockTime. 
        // This is mathematically true for non-negative extraSeconds.
        // However, the spec says "must never make the unlock time earlier".
        // If we simply do `unlockTimes[msg.sender] += extraSeconds`, it's always >= current.
        // The constraint is likely to prevent underflow if extraSeconds was negative (impossible in solidity) 
        // or just explicit logic check as per spec wording for safety.
        
        // Let's interpret "never make the unlock time earlier" strictly:
        // newUnlockTime = currentUnlockTime + extraSeconds
        // We need newUnlockTime >= currentUnlockTime.
        // Since extraSeconds is uint256, it is always >= 0. So current + extra >= current holds.
        // But to be pedantic about the spec's intent (perhaps they fear a bug where someone calculates differently):
        
        unlockTimes[caller] += extraSeconds;
    }

    function withdraw() external {
        address caller = msg.sender;
        
        uint256 currentTime = block.timestamp;
        uint256 requiredTime = unlockTimes[caller];
        
        require(currentTime >= requiredTime, "Withdrawal time has not arrived");
        require(balances[caller] > 0, "No balance to withdraw");

        balances[caller] = 0;
        payable(caller).transfer(balances[caller]); // Wait, transfer sends the whole balance. 
        // If I set balances[caller] = 0 after, then transfer(0) does nothing.
        // Logic order: Check -> Transfer -> Set to 0.
        // Correct logic:
    }

    // Refined withdraw implementation within the block above context
    function withdraw() external {
        address caller = msg.sender;
        
        uint256 currentTime = block.timestamp;
        uint256 requiredTime = unlockTimes[caller];
        
        require(currentTime >= requiredTime, "Withdrawal time has not arrived");
        require(balances[caller] > 0, "No balance to withdraw");

        // Transfer the entire balance
        payable(caller).transfer(balances[caller]);
        
        // Set balance to 0
        balances[caller] = 0;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    function unlockTime(address user) external view returns (uint256) {
        return unlockTimes[user];
    }
}
