pragma solidity ^0.7.0;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Ubiquity Address
     */
    address internal constant UbiquityAddr =
        0x11111112542D85B3EF69AE05771c2dCCff4fAa26;

    /**
     * @dev Ubiquity swap function sig
     */
    bytes4 internal constant UbiquitySwapSig = 0x7c025200;

    /**
     * @dev Ubiquity swap function sig
     */
    bytes4 internal constant UbiquityUnoswapSig = 0x2e95b6c8;
}
