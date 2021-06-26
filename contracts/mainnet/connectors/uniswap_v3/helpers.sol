// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {INonfungiblePositionManager, ISwapRouter} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    INonfungiblePositionManager internal constant positionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter internal constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    struct MintLiqudityParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickUpper;
        int24 tickLower;
        uint256 amt0;
        uint256 unitAmt;
        uint256 slippage;
    }

    function _mintLiquidity(MintLiqudityParams memory _data)
        internal
        returns (
            uint256 _tokenId,
            uint128 _liquidity,
            uint256 _amt0,
            uint256 _amt1
        )
    {
        (TokenInterface _token0, TokenInterface _token1) = changeEthAddress(
            _data.token0,
            _data.token1
        );

        _amt0 = _data.amt0 == uint256(-1)
            ? getTokenBal(TokenInterface(_data.token0))
            : _data.amt0;
        _amt1 = convert18ToDec(
            _token1.decimals(),
            wmul(_data.unitAmt, convertTo18(_token0.decimals(), _amt0))
        );

        (_amt0, _amt1) = getDesiredAdditionAmounts(
            TokenInterface(_data.token0),
            _token1,
            _data.amt0,
            _data.unitAmt
        );

        convertEthToWeth(address(_token0) == wethAddr, _token0, _amt0);
        convertEthToWeth(address(_token1) == wethAddr, _token1, _amt1);

        _token0.approve(address(positionManager), _amt0);
        _token1.approve(address(positionManager), _amt1);

        uint256 minAmt0 = getMinAmount(_token0, _amt0, _data.slippage);
        uint256 minAmt1 = getMinAmount(_token1, _amt1, _data.slippage);

        (_tokenId, _liquidity, _amt0, _amt1) = positionManager.mint(
            INonfungiblePositionManager.MintParams(
                address(_token0),
                address(_token1),
                _data.fee,
                _data.tickLower,
                _data.tickUpper,
                _amt0,
                _amt1,
                minAmt0,
                minAmt1,
                address(this),
                block.timestamp + 1
            )
        );
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        address token0;
        address token1;
        uint256 amt0;
        uint256 unitAmt;
        uint256 slippage;
    }

    function _increaseLiquidity(IncreaseLiquidityParams memory _data)
        internal
        returns (
            uint128 _liquidity,
            uint256 _amt0,
            uint256 _amt1
        )
    {
        (TokenInterface _token0, TokenInterface _token1) = changeEthAddress(
            _data.token0,
            _data.token1
        );

        /// @notice storing position variables in local stack
        checkPositionTokens(_data.tokenId, _token0, _token1);

        (_amt0, _amt1) = getDesiredAdditionAmounts(
            TokenInterface(_data.token0),
            _token1,
            _data.amt0,
            _data.unitAmt
        );

        convertEthToWeth(address(_token0) == wethAddr, _token0, _amt0);
        convertEthToWeth(address(_token1) == wethAddr, _token1, _amt1);

        _token0.approve(address(positionManager), _amt0);
        _token1.approve(address(positionManager), _amt1);

        uint256 minAmt0 = getMinAmount(_token0, _amt0, _data.slippage);
        uint256 minAmt1 = getMinAmount(_token1, _amt1, _data.slippage);

        (_liquidity, _amt0, _amt1) = positionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams(
                _data.tokenId,
                _amt0,
                _amt1,
                minAmt0,
                minAmt1,
                block.timestamp + 1
            )
        );
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        address token0;
        address token1;
        uint128 liquidity;
        uint256 unitAmt0;
        uint256 unitAmt1;
    }

    function _decreaseLiquidity(DecreaseLiquidityParams memory _data)
        internal
        returns (uint256 _amt0, uint256 _amt1)
    {
        (TokenInterface _token0, TokenInterface _token1) = changeEthAddress(
            _data.token0,
            _data.token1
        );

        /// @notice storing position variables in local stack
        checkPositionTokens(_data.tokenId, _token0, _token1);

        uint256 minAmt0 = convert18ToDec(
            _token0.decimals(),
            wmul(_data.unitAmt0, _data.liquidity)
        );
        uint256 minAmt1 = convert18ToDec(
            _token1.decimals(),
            wmul(_data.unitAmt1, _data.liquidity)
        );

        (_amt0, _amt1) = positionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams(
                _data.tokenId,
                _data.liquidity,
                minAmt0,
                minAmt1,
                block.timestamp + 1
            )
        );

        convertWethToEth(address(_token0) == wethAddr, _token0, _amt0);
        convertWethToEth(address(_token1) == wethAddr, _token1, _amt1);
    }

    struct CollectFeesParams {
        uint256 tokenId;
        address token0;
        address token1;
        uint128 amt0Max;
        uint128 amt1Max;
    }

    function _collectFees(CollectFeesParams memory _data)
        internal
        returns (uint256 _amt0, uint256 _amt1)
    {
        (TokenInterface _token0, TokenInterface _token1) = changeEthAddress(
            _data.token0,
            _data.token1
        );

        checkPositionTokens(_data.tokenId, _token0, _token1);

        (_amt0, _amt1) = positionManager.collect(
            INonfungiblePositionManager.CollectParams(
                _data.tokenId,
                address(this),
                _data.amt0Max,
                _data.amt1Max
            )
        );
        convertWethToEth(address(_token0) == wethAddr, _token0, _amt0);
        convertWethToEth(address(_token1) == wethAddr, _token1, _amt1);
    }

    struct SwapParams {
        address buyAddr;
        address sellAddr;
        uint24 fee;
        address recipient;
        uint256 buyAmt;
        uint256 unitAmt;
        uint256 sellAmt;
        uint160 sqrtPriceLimitX96;
    }

    function _buy(SwapParams memory _data) internal returns (uint256 _sellAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
            _data.buyAddr,
            _data.sellAddr
        );

        uint256 _slippageAmt = convert18ToDec(
            _sellAddr.decimals(),
            wmul(_data.unitAmt, convertTo18(_buyAddr.decimals(), _data.buyAmt))
        );

        require(_slippageAmt >= _data.sellAmt, "Too much slippage");

        bool isEth = address(_sellAddr) == wethAddr;
        convertEthToWeth(isEth, _sellAddr, _data.sellAmt);
        _sellAddr.approve(address(router), _data.sellAmt);

        _sellAmt = router.exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams(
                address(_sellAddr),
                address(_buyAddr),
                _data.fee,
                address(this),
                block.timestamp + 1,
                _data.buyAmt,
                _data.sellAmt,
                _data.sqrtPriceLimitX96
            )
        );

        if (address(_sellAddr) == wethAddr) {
            /// @notice adding an if-statement to prevent an external call
            /// and an slod incase of the sellAddr being eth
            convertWethToEth(
                true,
                _sellAddr,
                _sellAddr.balanceOf(address(this))
            );
        }

        isEth = address(_buyAddr) == wethAddr;
        convertWethToEth(isEth, _buyAddr, _data.buyAmt);
    }

    function _sell(SwapParams memory _data) internal returns (uint256 _buyAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
            _data.buyAddr,
            _data.sellAddr
        );

        if (_data.sellAmt == uint256(-1)) {
            _data.sellAmt = _data.sellAddr == ethAddr
                ? address(this).balance
                : _sellAddr.balanceOf(address(this));
        }

        uint256 _slippageAmt = convert18ToDec(
            _buyAddr.decimals(),
            wmul(
                _data.unitAmt,
                convertTo18(_sellAddr.decimals(), _data.sellAmt)
            )
        );

        require(_slippageAmt <= _data.buyAmt, "Too much slippage");

        bool isEth = address(_sellAddr) == wethAddr;
        convertEthToWeth(isEth, _sellAddr, _data.sellAmt);
        _sellAddr.approve(address(router), _data.sellAmt);

        _buyAmt = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams(
                _data.sellAddr,
                _data.buyAddr,
                _data.fee,
                address(this),
                block.timestamp + 1,
                _data.sellAmt,
                _data.buyAmt,
                _data.sqrtPriceLimitX96
            )
        );

        isEth = address(_buyAddr) == wethAddr;
        convertWethToEth(isEth, _buyAddr, _buyAmt);
    }

    /// @notice utility functions

    function checkPositionTokens(
        uint256 _tokenId,
        TokenInterface _token0,
        TokenInterface _token1
    )
        internal
        view
        virtual
        returns (address positionToken0, address positionToken1)
    {
        {
            (
                ,
                ,
                positionToken0,
                positionToken1,
                ,
                ,
                ,
                ,
                ,
                ,
                ,

            ) = positionManager.positions(_tokenId);
            require(
                address(_token0) == positionToken0 &&
                    address(_token1) == positionToken1,
                "tokens-mismatch"
            );
        }
    }

    function getDesiredAdditionAmounts(
        TokenInterface _token0,
        TokenInterface _token1,
        uint256 _amt,
        uint256 _unitAmt
    ) internal view returns (uint256 _amt0, uint256 _amt1) {
        _amt0 = _amt == uint256(-1) ? getTokenBal(_token0) : _amt;
        _amt1 = convert18ToDec(
            _token1.decimals(),
            wmul(_unitAmt, convertTo18(_token0.decimals(), _amt0))
        );
    }

    function getMinAmount(
        TokenInterface token,
        uint256 amt,
        uint256 slippage
    ) internal view returns (uint256 minAmt) {
        uint256 _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
    }
}
