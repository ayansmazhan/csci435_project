// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PiggyBank {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        if (msg.value == 0) revert("Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        balances[msg.sender] -= amount;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}
