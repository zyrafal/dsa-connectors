// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Ubiquity.
 * @dev Ubiquity Dollar (uAD).
 */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TokenInterface, MemoryInterface} from "../../common/interfaces.sol";
import {Stores} from "../../common/stores.sol";
import {UbiquityBondingV2} from "./interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract UbiquityResolver is Helpers, Events {
    /**
     * @dev Deposit LP uAD3CRV-f tokens into Ubiquity protocol
     * @notice Curve LP rewards upon uAD, USDC, USDT or DAI deposits
     * @notice in uAD3RCV-f metapool (https://crv.to/pool)
     * @param lpAmount Amount of LP tokens to deposit (For max: `uint256(-1)`)
     * @param durationWeeks Duration in weeks tokens will be locked (4-208)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
     */
    function deposit(
        uint256 lpAmount,
        uint256 durationWeeks,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _lpAmount = getUint(getId, lpAmount);

        if (_lpAmount == uint256(-1)) {
            _lpAmount = IERC20(UbiquityUAD3CRVf).balanceOf(address(this));
        }

        uint256 bondingShareId = UbiquityBondingV2(UbiquityBondingV2Address)
            .deposit(_lpAmount, durationWeeks);

        setUint(setId, bondingShareId);

        _eventName = "Deposit(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            address(this),
            bondingShareId,
            _lpAmount,
            durationWeeks,
            getId,
            setId
        );
    }
}

contract ConnectV2Ubiquity is UbiquityResolver {
    string public constant name = "Ubiquity-v1";
}
