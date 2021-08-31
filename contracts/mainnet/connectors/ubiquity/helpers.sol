// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Ubiquity BondingV2 Address
     */
    address internal constant UbiquityBonding =
        0xC251eCD9f1bD5230823F9A0F99a44A87Ddd4CA38;

    /**
     * @dev Ubiquity uAD Address
     */
    address internal constant UbiquityUAD =
        0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6;

    /**
     * @dev DAI Address
     */
    address internal constant UbiquityDAI =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;

    /**
     * @dev USDC Address
     */
    address internal constant UbiquityUSDC =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /**
     * @dev USDT Address
     */
    address internal constant UbiquityUSDT =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /**
     * @dev Curve 3CRV Token Address
     */
    address internal constant Ubiquity3CRV =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    /**
     * @dev Curve 3Pool Address
     */
    address internal constant Ubiquity3Pool =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    /**
     * @dev Curve uAD3CRV-f Token Address
     */
    address internal constant UbiquityUAD3CRVf =
        0x20955CB69Ae1515962177D164dfC9522feef567E;
}
