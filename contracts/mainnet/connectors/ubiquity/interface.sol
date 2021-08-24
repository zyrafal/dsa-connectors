pragma solidity ^0.7.0;

import {TokenInterface} from "../../common/interfaces.sol";

interface UbiquityInterace {
    function deposit(uint256 lpAmount, uint256 weeksAmount)
        external
        returns (uint256 bondingShareId);
}
