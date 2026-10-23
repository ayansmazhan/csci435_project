// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PiggyBank {
    mapping(address => uint256) private balances;

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(amount <= balances[msg.sender], "insufficient balance");
        balances[msg.sender] -= amount;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}
