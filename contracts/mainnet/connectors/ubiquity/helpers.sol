// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Ubiquity BondingV2 Address
     */
    address internal constant UbiquityBondingV2Address =
        0xC251eCD9f1bD5230823F9A0F99a44A87Ddd4CA38;

    /**
     * @dev Ubiquity uAD3CRV-f Curve Metapool Address
     */
    address internal constant UbiquityUAD3CRVf =
        0x20955CB69Ae1515962177D164dfC9522feef567E;
}
