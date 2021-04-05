pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import {
    AaveV1Interface,
    AaveV1CoreInterface,
    ATokenV1Interface,
    AaveV2Interface,
    CTokenInterface,
    CETHInterface,
    Protocol,
    RefinanceData,
    CommonData
} from "./interface.sol";

contract CompoundHelpers is Helpers {
    function _compEnterMarkets(uint length, CTokenInterface[] memory ctokens) internal {
        address[] memory _cTokens = new address[](length);

        for (uint i = 0; i < length; i++) {
            _cTokens[i] = address(ctokens[i]);
        }
        troller.enterMarkets(_cTokens);
    }

    function _compBorrowOne(
        uint fee,
        CTokenInterface ctoken,
        TokenInterface token,
        uint amt,
        Protocol target,
        uint rateMode
    ) internal returns (uint) {
        if (amt > 0) {
            address _token = address(token) == wethAddr ? ethAddr : address(token);

            if (amt == uint(-1)) {
                amt = getMaxBorrow(target, _token, ctoken, rateMode);
            }

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, true);

            require(ctoken.borrow(_amt) == 0, "borrow-failed-collateral?");
            transferFees(_token, feeAmt);
        }
        return amt;
    }

    function _compBorrow(
        RefinanceData memory data,
        CommonData memory commonData
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](commonData.length);
        for (uint i = 0; i < commonData.length; i++) {
            finalAmts[i] = _compBorrowOne(
                data.debtFee, 
                commonData.ctokens[i], 
                commonData.tokens[i], 
                data.borrowAmts[i], 
                data.source, 
                data.borrowRateModes[i]
            );
        }
        return finalAmts;
    }

    function _compDepositOne(uint fee, CTokenInterface ctoken, TokenInterface token, uint amt) internal {
        if (amt > 0) {
            address _token = address(token) == wethAddr ? ethAddr : address(token);

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, false);

            if (_token != ethAddr) {
                token.approve(address(ctoken), _amt);
                require(ctoken.mint(_amt) == 0, "deposit-failed");
            } else {
                CETHInterface(address(ctoken)).mint{value: _amt}();
            }
            transferFees(_token, feeAmt);
        }
    }

    function _compDeposit(
        RefinanceData memory data,
        CommonData memory commonData
    ) internal {
        for (uint i = 0; i < commonData.length; i++) {
            _compDepositOne(data.collateralFee, commonData.ctokens[i], commonData.tokens[i], commonData.depositAmts[i]);
        }
    }

    function _compWithdrawOne(CTokenInterface ctoken, TokenInterface token, uint amt) internal returns (uint) {
        if (amt > 0) {
            if (amt == uint(-1)) {
                bool isEth = address(token) == wethAddr;
                uint initalBal = isEth ? address(this).balance : token.balanceOf(address(this));
                require(ctoken.redeem(ctoken.balanceOf(address(this))) == 0, "withdraw-failed");
                uint finalBal = isEth ? address(this).balance : token.balanceOf(address(this));
                amt = sub(finalBal, initalBal);
            } else {
                require(ctoken.redeemUnderlying(amt) == 0, "withdraw-failed");
            }
        }
        return amt;
    }

    function _compWithdraw(
        RefinanceData memory data,
        CommonData memory commonData
    ) internal returns(uint[] memory) {
        uint[] memory finalAmts = new uint[](commonData.length);
        for (uint i = 0; i < commonData.length; i++) {
            finalAmts[i] = _compWithdrawOne(commonData.ctokens[i], commonData.tokens[i], data.withdrawAmts[i]);
        }
        return finalAmts;
    }

    function _compPaybackOne(CTokenInterface ctoken, TokenInterface token, uint amt) internal returns (uint) {
        if (amt > 0) {
            if (amt == uint(-1)) {
                amt = ctoken.borrowBalanceCurrent(address(this));
            }
            if (address(token) != wethAddr) {
                token.approve(address(ctoken), amt);
                require(ctoken.repayBorrow(amt) == 0, "repay-failed.");
            } else {
                CETHInterface(address(ctoken)).repayBorrow{value: amt}();
            }
        }
        return amt;
    }

    function _compPayback(
        CommonData memory commonData
    ) internal {
        for (uint i = 0; i < commonData.length; i++) {
            _compPaybackOne(commonData.ctokens[i], commonData.tokens[i], commonData.paybackAmts[i]);
        }
    }
}

contract AaveV1Helpers is CompoundHelpers {
    function _aaveV1BorrowOne(
        AaveV1Interface aave,
        uint fee,
        Protocol target,
        TokenInterface token,
        CTokenInterface ctoken,
        uint amt,
        uint borrowRateMode,
        uint paybackRateMode
    ) internal returns (uint) {
        if (amt > 0) {

            address _token = address(token) == wethAddr ? ethAddr : address(token);

            if (amt == uint(-1)) {
                amt = getMaxBorrow(target, _token, ctoken, paybackRateMode);
            }

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, true);

            aave.borrow(_token, _amt, borrowRateMode, referralCode);
            transferFees(_token, feeAmt);
        }
        return amt;
    }

    function _aaveV1Borrow(
        RefinanceData memory data,
        CommonData memory commonData
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](commonData.length);
        for (uint i = 0; i < commonData.length; i++) {
            finalAmts[i] = _aaveV1BorrowOne(
                commonData.aaveV1,
                data.debtFee,
                data.source,
                commonData.tokens[i],
                commonData.ctokens[i],
                data.borrowAmts[i],
                data.borrowRateModes[i],
                data.paybackRateModes[i]
            );
        }
        return finalAmts;
    }

    function _aaveV1DepositOne(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        uint fee,
        TokenInterface token,
        uint amt
    ) internal {
        if (amt > 0) {
            uint ethAmt;
            (uint feeAmt, uint _amt) = calculateFee(amt, fee, false);

            bool isEth = address(token) == wethAddr;

            address _token = isEth ? ethAddr : address(token);

            if (isEth) {
                ethAmt = _amt;
            } else {
                token.approve(address(aaveCore), _amt);
            }

            transferFees(_token, feeAmt);

            aave.deposit{value: ethAmt}(_token, _amt, referralCode);

            if (!getIsColl(aave, _token))
                aave.setUserUseReserveAsCollateral(_token, true);
        }
    }

    function _aaveV1Deposit(
        RefinanceData memory data,
        CommonData memory commonData
    ) internal {
        for (uint i = 0; i < commonData.length; i++) {
            _aaveV1DepositOne(
                commonData.aaveV1,
                commonData.aaveCore,
                data.collateralFee,
                commonData.tokens[i],
                commonData.depositAmts[i]
            );
        }
    }

    function _aaveV1WithdrawOne(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        TokenInterface token,
        uint amt
    ) internal returns (uint) {
        if (amt > 0) {
            address _token = address(token) == wethAddr ? ethAddr : address(token);
            ATokenV1Interface atoken = ATokenV1Interface(aaveCore.getReserveATokenAddress(_token));
            if (amt == uint(-1)) {
                amt = getWithdrawBalance(aave, _token);
            }
            atoken.redeem(amt);
        }
        return amt;
    }

    function _aaveV1Withdraw(
        RefinanceData memory data,
        CommonData memory commonData
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](commonData.length);
        for (uint i = 0; i < commonData.length; i++) {
            finalAmts[i] = _aaveV1WithdrawOne(
                commonData.aaveV1,
                commonData.aaveCore,
                commonData.tokens[i],
                data.withdrawAmts[i]
            );
        }
        return finalAmts;
    }

    function _aaveV1PaybackOne(
        AaveV1Interface aave,
        AaveV1CoreInterface aaveCore,
        TokenInterface token,
        uint amt
    ) internal returns (uint) {
        if (amt > 0) {
            uint ethAmt;

            bool isEth = address(token) == wethAddr;

            address _token = isEth ? ethAddr : address(token);

            if (amt == uint(-1)) {
                (uint _amt, uint _fee) = getPaybackBalance(aave, _token);
                amt = _amt + _fee;
            }

            if (isEth) {
                ethAmt = amt;
            } else {
                token.approve(address(aaveCore), amt);
            }

            aave.repay{value: ethAmt}(_token, amt, payable(address(this)));
        }
        return amt;
    }

    function _aaveV1Payback(
        CommonData memory commonData
    ) internal {
        for (uint i = 0; i < commonData.length; i++) {
            _aaveV1PaybackOne(
                commonData.aaveV1,
                commonData.aaveCore,
                commonData.tokens[i],
                commonData.paybackAmts[i]
            );
        }
    }
}

contract AaveV2Helpers is AaveV1Helpers {
    function _aaveV2BorrowOne(
        AaveV2Interface aave,
        uint fee,
        Protocol target,
        TokenInterface token,
        CTokenInterface ctoken,
        uint amt,
        uint rateMode
    ) internal returns (uint) {
        if (amt > 0) {
            bool isEth = address(token) == wethAddr;
            
            address _token = isEth ? ethAddr : address(token);

            if (amt == uint(-1)) {
                amt = getMaxBorrow(target, _token, ctoken, rateMode);
            }

            (uint feeAmt, uint _amt) = calculateFee(amt, fee, true);

            aave.borrow(address(token), _amt, rateMode, referralCode, address(this));
            convertWethToEth(isEth, token, amt);

            transferFees(_token, feeAmt);
        }
        return amt;
    }

    function _aaveV2Borrow(
        RefinanceData memory data,
        CommonData memory commonData
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](commonData.length);
        for (uint i = 0; i < commonData.length; i++) {
            finalAmts[i] = _aaveV2BorrowOne(
                commonData.aaveV2,
                data.debtFee,
                data.source,
                commonData.tokens[i],
                commonData.ctokens[i],
                data.borrowAmts[i],
                data.borrowRateModes[i]
            );
        }
        return finalAmts;
    }

    function _aaveV2DepositOne(
        AaveV2Interface aave,
        uint fee,
        TokenInterface token,
        uint amt
    ) internal {
        if (amt > 0) {
            (uint feeAmt, uint _amt) = calculateFee(amt, fee, false);

            bool isEth = address(token) == wethAddr;
            address _token = isEth ? ethAddr : address(token);

            transferFees(_token, feeAmt);

            convertEthToWeth(isEth, token, _amt);

            token.approve(address(aave), _amt);

            aave.deposit(address(token), _amt, address(this), referralCode);

            if (!getIsCollV2(address(token))) {
                aave.setUserUseReserveAsCollateral(address(token), true);
            }
        }
    }

    function _aaveV2Deposit(
        RefinanceData memory data,
        CommonData memory commonData
    ) internal {
        for (uint i = 0; i < commonData.length; i++) {
            _aaveV2DepositOne(
                commonData.aaveV2,
                data.collateralFee,
                commonData.tokens[i],
                commonData.depositAmts[i]
            );
        }
    }

    function _aaveV2WithdrawOne(
        AaveV2Interface aave,
        TokenInterface token,
        uint amt
    ) internal returns (uint _amt) {
        if (amt > 0) {
            bool isEth = address(token) == wethAddr;

            _amt = amt == uint(-1) ? getWithdrawBalanceV2(address(token)) : amt;

            aave.withdraw(address(token), amt, address(this));

            convertWethToEth(isEth, token, _amt);
        }
    }

    function _aaveV2Withdraw(
        RefinanceData memory data,
        CommonData memory commonData
    ) internal returns (uint[] memory) {
        uint[] memory finalAmts = new uint[](commonData.length);
        for (uint i = 0; i < commonData.length; i++) {
            finalAmts[i] = _aaveV2WithdrawOne(
                commonData.aaveV2,
                commonData.tokens[i],
                data.withdrawAmts[i]
            );
        }
        return finalAmts;
    }

    function _aaveV2PaybackOne(
        AaveV2Interface aave,
        TokenInterface token,
        uint amt,
        uint rateMode
    ) internal returns (uint _amt) {
        if (amt > 0) {
            bool isEth = address(token) == wethAddr;

            _amt = amt == uint(-1) ? getPaybackBalanceV2(address(token), rateMode) : amt;

            convertEthToWeth(isEth, token, _amt);

            token.approve(address(aave), _amt);

            aave.repay(address(token), _amt, rateMode, address(this));
        }
    }

    function _aaveV2Payback(
        RefinanceData memory data,
        CommonData memory commonData
    ) internal {
        for (uint i = 0; i < commonData.length; i++) {
            _aaveV2PaybackOne(
                commonData.aaveV2,
                commonData.tokens[i],
                commonData.paybackAmts[i],
                data.paybackRateModes[i]
            );
        }
    }
}

contract RefinanceResolver is AaveV2Helpers {

    function refinance(RefinanceData calldata data) external payable {
        require(data.source != data.target, "source-and-target-unequal");

        CommonData memory commonData;

        commonData.length = data.tokens.length;

        require(data.borrowAmts.length == commonData.length, "length-mismatch");
        require(data.withdrawAmts.length == commonData.length, "length-mismatch");
        require(data.borrowRateModes.length == commonData.length, "length-mismatch");
        require(data.paybackRateModes.length == commonData.length, "length-mismatch");

        commonData.aaveV2 = AaveV2Interface(aaveV2Provider.getLendingPool());
        commonData.aaveV1 = AaveV1Interface(aaveV1Provider.getLendingPool());
        commonData.aaveCore = AaveV1CoreInterface(aaveV1Provider.getLendingPoolCore());

        commonData.tokens = getTokenInterfaces(commonData.length, data.tokens);
        // commonData.ctokens = getCtokenInterfaces(commonData.length, data.tokens);

        if (data.source == Protocol.Aave && data.target == Protocol.AaveV2) {
            commonData.paybackAmts = _aaveV2Borrow(data, commonData);
            _aaveV1Payback(commonData);
            commonData.depositAmts = _aaveV1Withdraw(data, commonData);
            _aaveV2Deposit(data, commonData);
        } else if (data.source == Protocol.Aave && data.target == Protocol.Compound) {
            _compEnterMarkets(commonData.length, commonData.ctokens);

            commonData.paybackAmts = _compBorrow(data, commonData);
            _aaveV1Payback(commonData);
            commonData.depositAmts = _aaveV1Withdraw(data, commonData);
            _compDeposit(data, commonData);
        } else if (data.source == Protocol.AaveV2 && data.target == Protocol.Aave) {
            commonData.paybackAmts = _aaveV1Borrow(data, commonData);
            _aaveV2Payback(data, commonData);
            commonData.depositAmts = _aaveV2Withdraw(data, commonData);
            _aaveV1Deposit(data, commonData);
        } else if (data.source == Protocol.AaveV2 && data.target == Protocol.Compound) {
            _compEnterMarkets(commonData.length, commonData.ctokens);

            commonData.paybackAmts = _compBorrow(data, commonData);
            _aaveV2Payback(data, commonData);
            commonData.depositAmts = _aaveV2Withdraw(data, commonData);
            _compDeposit(data, commonData);
        } else if (data.source == Protocol.Compound && data.target == Protocol.Aave) {
            commonData.paybackAmts = _aaveV1Borrow(data, commonData);
            _compPayback(commonData);
            commonData.depositAmts = _compWithdraw(data, commonData);
            _aaveV1Deposit(data, commonData);
        } else if (data.source == Protocol.Compound && data.target == Protocol.AaveV2) {
            commonData.paybackAmts = _aaveV2Borrow(data, commonData);
            _compPayback(commonData);
            commonData.depositAmts = _compWithdraw(data, commonData);
            _aaveV2Deposit(data, commonData);
        } else {
            revert("invalid-options");
        }
    }
}

contract ConnectRefinance is RefinanceResolver {
    string public name = "Refinance-v1.2";
}