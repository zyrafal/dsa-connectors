// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Ubiquity.
 * @dev Ubiquity Dollar (uAD).
 */

import {TokenInterface, MemoryInterface} from "../../common/interfaces.sol";
import {Stores} from "../../common/stores.sol";
import {SafeMath} from "../../common/math.sol";
import {IUbiquityBondingV2, IUbiquityMetaPool, IUbiquity3Pool} from "./interfaces.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract UbiquityResolver is Helpers, Events {
    /**
     * @dev Deposit into Ubiquity protocol
     * @notice 3POOL (DAI / USDC / USDT) => METAPOOL (3CRV / uAD) => uAD3CRV-f => Ubiquity BondingShare
     * @notice STEP 1 : 3POOL (DAI / USDC / USDT) => 3CRV
     * @notice STEP 2 : METAPOOL(3CRV / UAD) => uAD3CRV-f
     * @notice STEP 3 : uAD3CRV-f => Ubiquity BondingShare
     * @param token Token deposited : DAI, USDC, USDT, 3CRV, uAD or uAD3CRV-f
     * @param amount Amount of tokens to deposit (For max: `uint256(-1)`)
     * @param durationWeeks Duration in weeks tokens will be locked (4-208)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
     */
    function deposit(
        address token,
        uint256 amount,
        uint256 durationWeeks,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        bool step1 = token == UbiquityDAI ||
            token == UbiquityUSDC ||
            token == UbiquityUSDT;
        bool step2 = step1 || token == UbiquityUAD || token == Ubiquity3CRV;

        require(step1 || step2 || token == UbiquityUAD3CRVf);

        uint256 _amount = getUint(getId, amount);
        uint256 _crvAmount;
        uint256 _lpAmount;

        // Full balance if amount = -1
        if (_amount == uint256(-1)) {
            _amount = TokenInterface(token).balanceOf(address(this));
        }

        // STEP 1
        if (step1) {
            uint256[3] memory amounts1;
            uint8 index1;

            if (token == UbiquityUSDT) index1 = 2;
            else if (token == UbiquityUSDC) index1 = 1;
            amounts1[index1] = _amount;

            // Deposit DAI, USDC or USDT into 3Pool to get 3Crv LPs
            TokenInterface(token).approve(Ubiquity3Pool, 0);
            TokenInterface(token).approve(Ubiquity3Pool, _amount);
            IUbiquity3Pool(Ubiquity3Pool).add_liquidity(amounts1, 0);
        }

        // STEP 2
        if (step2) {
            uint256[2] memory amounts2;
            uint8 index2;
            address token2 = token;

            if (token == UbiquityUAD) {
                _crvAmount = _amount;
            } else {
                index2 = 1;
                if (token == Ubiquity3CRV) {
                    _crvAmount = _amount;
                } else {
                    token2 = Ubiquity3CRV;
                    _crvAmount = TokenInterface(token2).balanceOf(
                        address(this)
                    );
                }
            }
            amounts2[index2] = _crvAmount;

            // Deposit in uAD3CRV pool to get uAD3CRV-f LPs
            TokenInterface(token2).approve(UbiquityUAD3CRVf, 0);
            TokenInterface(token2).approve(UbiquityUAD3CRVf, _crvAmount);
            _lpAmount = IUbiquityMetaPool(UbiquityUAD3CRVf).add_liquidity(
                amounts2,
                0
            );
        }

        // STEP 3
        if (token == UbiquityUAD3CRVf) {
            _lpAmount = _amount;
        }

        // Deposit uAD3CRV-f LPs into UbiquityBondingV2 and get Ubiquity Bonding Shares
        TokenInterface(UbiquityUAD3CRVf).approve(UbiquityBonding, 0);
        TokenInterface(UbiquityUAD3CRVf).approve(UbiquityBonding, _lpAmount);
        uint256 bondingShareId = IUbiquityBondingV2(UbiquityBonding).deposit(
            _lpAmount,
            durationWeeks
        );

        setUint(setId, bondingShareId);

        _eventName = "Deposit(address,address,uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            address(this),
            token,
            amount,
            _lpAmount,
            durationWeeks,
            bondingShareId,
            getId,
            setId
        );
    }
}

contract ConnectV2Ubiquity is UbiquityResolver {
    string public constant name = "Ubiquity-v1";
}
