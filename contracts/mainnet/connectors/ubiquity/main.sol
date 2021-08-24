pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Ubiquity.
 * @dev Ubiquity Dollar (uAD).
 */

// import files from common directory
import {TokenInterface, MemoryInterface} from "../../common/interfaces.sol";
import {Stores} from "../../common/stores.sol";
import {UbiquityInterace} from "./interface.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract UbiquityResolver is Helpers, Events {
    /**
     * @dev Deposit ETH into WETH.
     * @notice Wrap ETH into WETH
     * @param lpAmount The amount of LP tokens to deposit. (For max: `uint256(-1)`)
     * @param weeksAmount The amount of weeks the tokens will be locked. (4-208)
     */
    function deposit(uint256 lpAmount, uint256 weeksAmount)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        // ...

        _eventName = "Deposit(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(lpAmount, weeksAmount);
    }
}

contract ConnectV2Ubiquity is UbiquityResolver {
    string public constant name = "Ubiquity-v1";
}
