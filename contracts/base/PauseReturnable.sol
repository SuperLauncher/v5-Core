// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;


contract PauseReturnable {

    bool private _paused;
    bool private _canReturn;
    bool private _hasSetReturnOnce;

    event SetPaused(bool pause);
    event SetReturnAble(bool returnable);
    event ReturnFund(address token, uint amount, address to);

    modifier notPaused() {
        require(!_paused, "Paused");
        _;
    }

    modifier canReturnFund() {
        require(_paused && _canReturn, "Cannot refund");
        _;
    }

    function isPausedReturnable() public view returns (bool paused, bool returnable) {
        return (_paused, _canReturn);
    }

    function _setPause(bool set) internal {
        // Cannot unpause if has set refundable previously //
        bool notAllowed = _hasSetReturnOnce && !set;
        require(!notAllowed, "Cannot unpause");
        if (_paused != set) {
            _paused = set;
            emit SetPaused(set);
        }
    }

    function _setReturnable(bool set) internal {
        require(_paused, "Not paused yet");
        if (!_hasSetReturnOnce && set) {
            _hasSetReturnOnce = true;
        }

        if (_canReturn != set) {
            _canReturn = set;
            emit SetReturnAble(set);
        }
    }
}
