// SPDX-License-Identifier: MIT
// Deliberately vulnerable control used to check that the attack test works. NOT a reference.
pragma solidity ^0.8.24;

contract PiggyBank {
    mapping(address => uint256) private balances;

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(amount <= balances[msg.sender], "insufficient balance");
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");
        balances[msg.sender] = 0;   // VULNERABLE: state updated after the call
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}
