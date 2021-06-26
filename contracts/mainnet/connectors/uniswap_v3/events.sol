// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogMintAndDepositLiquidity(
        uint256 indexed tokenId,
        address indexed token0,
        address indexed token1,
        uint128 liquidity,
        uint256 amt0,
        uint256 amt1,
        uint256 getId,
        uint256[] setIds
    );

    event LogDepositLiquidity(
        uint256 indexed tokenId,
        address indexed token0,
        address indexed token1,
        uint128 liquidity,
        uint256 amt0,
        uint256 amt1,
        uint256 getId,
        uint256 setId
    );

    event LogWithdrawLiquidity(
        uint256 indexed tokenId,
        address indexed token0,
        address indexed token1,
        uint256 amt0,
        uint256 amt1,
        uint256 getId,
        uint256[] setIds
    );

    event LogCollectFees(
        uint256 indexed tokenId,
        address indexed token0,
        address indexed token1,
        uint256 amt0Max,
        uint256 amt1Max
    );

    event LogBuy(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );
}
