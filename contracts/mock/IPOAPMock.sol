// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract IPOAPMock {
    mapping(address => mapping(uint256 => uint256)) public balances;

    function setBalance(address user, uint256 id, uint256 amount) public {
        balances[user][id] = amount;
    }

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256) {
        return balances[account][id];
    }
}