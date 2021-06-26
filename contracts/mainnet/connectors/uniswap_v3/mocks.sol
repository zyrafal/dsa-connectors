// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import {TokenInterface} from "../../common/interfaces.sol";
import {ConnectV2UniswapV3NFT} from "./main.sol";

contract MockUNIV3 is ConnectV2UniswapV3NFT {
    function internalBuy(SwapParams memory _data) external returns (uint256) {
        return _buy(_data);
    }

    function internalSell(SwapParams memory _data) external returns (uint256) {
        return _sell(_data);
    }

    function internalCollectFees(CollectFeesParams memory _data)
        external
        returns (uint256, uint256)
    {
        return _collectFees(_data);
    }

    function internalMintLiquidity(MintLiqudityParams memory _data)
        external
        returns (
            uint256,
            uint128,
            uint256,
            uint256
        )
    {
        return _mintLiquidity(_data);
    }

    function internalIncreaseLiquidity(IncreaseLiquidityParams memory _data)
        external
        returns (
            uint128,
            uint256,
            uint256
        )
    {
        return _increaseLiquidity(_data);
    }

    function internalDecreaseLiquidity(DecreaseLiquidityParams memory _data)
        external
        returns (uint256, uint256)
    {
        return _decreaseLiquidity(_data);
    }

    function internalCheckPositionTokens(
        uint256 _tokenId,
        TokenInterface _token0,
        TokenInterface _token1
    ) external view returns (address, address) {
        return checkPositionTokens(_tokenId, _token0, _token1);
    }
}
