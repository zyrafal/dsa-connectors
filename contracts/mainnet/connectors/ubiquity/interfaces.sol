// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {TokenInterface} from "../../common/interfaces.sol";

interface UbiquityBondingV2 {
    function deposit(uint256 lpAmount, uint256 durationWeeks)
        external
        returns (uint256 bondingShareId);
}
