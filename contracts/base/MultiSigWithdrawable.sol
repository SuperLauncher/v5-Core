// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "./TokenHelper.sol";
import "../Constant.sol";


contract MultiSigWithdrawable is TokenHelper {

    event MultiSigWithdraw(uint amount, address to);
    event MultiSigWithdrawToken(address token, uint amount, address to);

    function _multiSigWithdrawToken(address token, uint amount, address to) internal {
        _transferTokenOut(token, amount, to);
        emit MultiSigWithdrawToken(token, amount, to);
    }
}
