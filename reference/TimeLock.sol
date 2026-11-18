// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TimeLock {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _unlockTimes;

    function deposit(uint256 lockDuration) external payable {
        require(msg.value > 0, "zero deposit");
        _balances[msg.sender] += msg.value;
        uint256 newUnlock = block.timestamp + lockDuration;
        if (newUnlock > _unlockTimes[msg.sender]) {
            _unlockTimes[msg.sender] = newUnlock;   // only ever move the time later
        }
    }

    function increaseLockTime(uint256 extraSeconds) external {
        require(_balances[msg.sender] > 0, "nothing locked");
        // Checked arithmetic (Solidity >= 0.8): an overflow reverts instead of wrapping to a small number.
        _unlockTimes[msg.sender] += extraSeconds;
    }

    function withdraw() external {
        uint256 amount = _balances[msg.sender];
        require(amount > 0, "nothing to withdraw");
        require(block.timestamp >= _unlockTimes[msg.sender], "still locked");
        _balances[msg.sender] = 0;                     // effect before interaction
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    function unlockTime(address user) external view returns (uint256) {
        return _unlockTimes[user];
    }
}
