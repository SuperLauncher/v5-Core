
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;


contract Insurable {

    uint private _duration;

    function _configInsurance(uint duration) internal {
        _duration = duration;
    }

    function getInsuranceDuration() public view returns ( uint) {
        return _duration;
    }

    function _isInsuranceWindow(uint tgeTime) internal view returns (bool inPeriod, bool passedPeriod, uint start, uint end) {
        (start, end) = (tgeTime, tgeTime + _duration);
        inPeriod = block.timestamp > start && block.timestamp <= end;
        passedPeriod = block.timestamp > end;
    }
}