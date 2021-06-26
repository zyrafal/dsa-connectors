// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

/**
 * @title Uniswap V3 Connector.
 * @dev Uniswap V3 Connector to deposit, withdraw & swap.
 */

abstract contract UniswapV3Resolver is Helpers, Events {
    /**
     * @dev Deposit Liquidity for the first time
     * ie: while minting the NFT based on params
     */
    function mintAndDeposit(
        MintLiqudityParams memory _params,
        uint256 getId,
        uint256[] calldata setIds
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        _params.amt0 = getUint(getId, _params.amt0);

        (
            uint256 _tokenId,
            uint128 _liquidity,
            uint256 _amt0,
            uint256 _amt1
        ) = _mintLiquidity(_params);
        setUint(setIds[0], _tokenId);
        setUint(setIds[1], _liquidity);
        _eventName = "LogMintAndDepositLiquidity(uint256,address,address,uint128,uint256,uint256,uint256,uint256[])";
        _eventParam = abi.encode(
            _tokenId,
            _params.token0,
            _params.token1,
            _liquidity,
            _amt0,
            _amt1,
            getId,
            setIds
        );
    }

    function deposit(
        IncreaseLiquidityParams memory _params,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        _params.amt0 = getUint(getId, _params.amt0);
        (uint128 _liquidity, uint256 _amt0, uint256 _amt1) = _increaseLiquidity(
            _params
        );
        setUint(setId, uint256(_liquidity));

        _eventName = "LogDepositLiquidity(uint256,address,address,uint128,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            _params.tokenId,
            _params.token0,
            _params.token1,
            _liquidity,
            _amt0,
            _amt1,
            getId,
            setId
        );
    }

    function withdraw(
        DecreaseLiquidityParams memory _params,
        uint256 getId,
        uint256[] calldata setIds
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        _params.liquidity = uint128(getUint(getId, uint256(_params.liquidity)));
        (uint256 _amt0, uint256 _amt1) = _decreaseLiquidity(_params);

        setUint(setIds[0], _amt0);
        setUint(setIds[1], _amt1);
				
        _eventName = "LogWithdrawLiquidity(uint256,address,address,uint256,uint256,uint256,uint256[])";
        _eventParam = abi.encode(
            _params.tokenId,
            _params.token0,
            _params.token1,
            _amt0,
            _amt1,
            getId,
            setIds
        );
    }

    function collectFees(
        CollectFeesParams memory _params,
        uint256[] calldata getIds,
        uint256[] calldata setIds
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        _params.amt0Max = uint128(getUint(getIds[0], uint256(_params.amt0Max)));
        _params.amt1Max = uint128(getUint(getIds[0], uint256(_params.amt1Max)));

        _collectFees(_params);

        setUint(setIds[0], uint256(_params.amt0Max));
        setUint(setIds[1], uint256(_params.amt1Max));

        _eventName = "LogCollectFees(uint256,address,address,uint256,uint256)";
        _eventParam = abi.encode(
            _params.tokenId,
            _params.token0,
            _params.token1,
            _params.amt0Max,
            _params.amt1Max
        );
    }

    function buy(
        SwapParams memory _params,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        _params.buyAmt = getUint(getId, _params.buyAmt);

        uint256 _sellAmt = _buy(_params);

        setUint(setId, _sellAmt);

        _eventName = "LogBuy(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encodePacked(
            _params.buyAddr,
            _params.sellAddr,
            _params.buyAmt,
            _sellAmt,
            getId,
            setId
        );
    }

    function sell(
        SwapParams memory _params,
        uint256 setId,
        uint256 getId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        _params.sellAmt = getUint(getId, _params.sellAmt);

        uint256 _buyAmt = _sell(_params);

        setUint(setId, _buyAmt);

        _eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encodePacked(
            _params.buyAddr,
            _params.sellAddr,
            _buyAmt,
            _params.sellAmt,
            getId,
            setId
        );
    }
}

contract ConnectV2UniswapV3NFT is UniswapV3Resolver {
    string public constant name = "Uniswap-v3-NFT-v1.0";
}
