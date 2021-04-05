pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import {
    InstaCompoundMapping,
    ComptrollerInterface,
    AaveV1ProviderInterface,
    AaveV2LendingPoolProviderInterface,
    AaveV2DataProviderInterface,
    AaveV1Interface,
    CTokenInterface,
    Protocol,
    IERC20
} from "./interface.sol";
import { SafeERC20 } from "./libraries.sol";

contract Helpers is DSMath, Basic {
    using SafeERC20 for IERC20;

    address payable constant feeCollector = 0xb1DC62EC38E6E3857a887210C38418E4A17Da5B2;

    /**
     * @dev Compound Mapping
     */
    InstaCompoundMapping internal constant compMapping = InstaCompoundMapping(0xA8F9D4aA7319C54C04404765117ddBf9448E2082);

    /**
     * @dev Compound Comptroller
     */
    ComptrollerInterface internal constant troller = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    /**
     * @dev Aave v1 provider
     */
    AaveV1ProviderInterface internal constant aaveV1Provider = AaveV1ProviderInterface(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    /**
     * @dev Aave v2 provider
     */
    AaveV2LendingPoolProviderInterface internal constant aaveV2Provider = AaveV2LendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    /**
     * @dev Aave v2 data provider
     */
    AaveV2DataProviderInterface internal constant aaveV2Data = AaveV2DataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    uint16 internal constant referralCode = 3228;

    function getWithdrawBalance(AaveV1Interface aave, address token) internal view returns (uint bal) {
        (bal, , , , , , , , , ) = aave.getUserReserveData(token, address(this));
    }

    function getPaybackBalance(AaveV1Interface aave, address token) internal view returns (uint bal, uint fee) {
        (, bal, , , , , fee, , , ) = aave.getUserReserveData(token, address(this));
    }

    function getTotalBorrowBalance(AaveV1Interface aave, address token) internal view returns (uint amt) {
        (, uint bal, , , , , uint fee, , , ) = aave.getUserReserveData(token, address(this));
        amt = add(bal, fee);
    }

    function getWithdrawBalanceV2(address token) internal view returns (uint bal) {
        (bal, , , , , , , , ) = aaveV2Data.getUserReserveData(token, address(this));
    }

    function getPaybackBalanceV2(address token, uint rateMode) internal view returns (uint bal) {
        if (rateMode == 1) {
            (, bal, , , , , , , ) = aaveV2Data.getUserReserveData(token, address(this));
        } else {
            (, , bal, , , , , , ) = aaveV2Data.getUserReserveData(token, address(this));
        }
    }

    function getIsColl(AaveV1Interface aave, address token) internal view returns (bool isCol) {
        (, , , , , , , , , isCol) = aave.getUserReserveData(token, address(this));
    }

    function getIsCollV2(address token) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveV2Data.getUserReserveData(token, address(this));
    }

    function getMaxBorrow(Protocol target, address token, CTokenInterface ctoken, uint rateMode) internal returns (uint amt) {
        AaveV1Interface aaveV1 = AaveV1Interface(aaveV1Provider.getLendingPool());

        if (target == Protocol.Aave) {
            (uint _amt, uint _fee) = getPaybackBalance(aaveV1, token);
            amt = _amt + _fee;
        } else if (target == Protocol.AaveV2) {
            amt = getPaybackBalanceV2(token, rateMode);
        } else if (target == Protocol.Compound) {
            amt = ctoken.borrowBalanceCurrent(address(this));
        }
    }

    function transferFees(address token, uint feeAmt) internal {
        if (feeAmt > 0) {
            if (token == ethAddr) {
                feeCollector.transfer(feeAmt);
            } else {
                IERC20(token).safeTransfer(feeCollector, feeAmt);
            }
        }
    }

    function calculateFee(uint256 amount, uint256 fee, bool toAdd) internal pure returns(uint feeAmount, uint _amount){
        feeAmount = wmul(amount, fee);
        _amount = toAdd ? add(amount, feeAmount) : sub(amount, feeAmount);
    }

    function getTokenInterfaces(uint length, address[] memory tokens) internal pure returns (TokenInterface[] memory) {
        TokenInterface[] memory _tokens = new TokenInterface[](length);
        for (uint i = 0; i < length; i++) {
            if (tokens[i] ==  ethAddr) {
                _tokens[i] = TokenInterface(wethAddr);
            } else {
                _tokens[i] = TokenInterface(tokens[i]);
            }
        }
        return _tokens;
    }

    // function getCtokenInterfaces(uint length, address[] memory tokens) internal view returns (CTokenInterface[] memory) {
    //     CTokenInterface[] memory _ctokens = new CTokenInterface[](length);
    //     for (uint i = 0; i < length; i++) {
    //         address _cToken = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);
    //         _ctokens[i] = CTokenInterface(_cToken);
    //     }
    //     return _ctokens;
    // }
}