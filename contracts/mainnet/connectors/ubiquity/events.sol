pragma solidity ^0.7.0;

contract Events {
    event Deposit(
        address indexed user,
        uint256 indexed bondingShareId,
        uint256 lpAmount,
        uint256 bondingShareAmount,
        uint256 weeksAmount,
        uint256 endBlock
    );
}
