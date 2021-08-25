// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Events {
    event Deposit(
        address indexed userAddress,
        uint256 indexed bondingShareId,
        uint256 lpAmount,
        uint256 durationWeeks,
        uint256 getId,
        uint256 setId
    );
}
