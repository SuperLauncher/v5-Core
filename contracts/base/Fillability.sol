// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "../Constant.sol";


contract Fillability {

    uint private _hardCap;
    uint[10] private _buckets; // 0: 0-999, 1:1000-1999, 2:2000-2999 ... 9:9999 and beyond

    
    function getFillability(uint sv) external view returns (uint) {

        (uint AboveAmt, uint ownBucketAmt, uint idx) = _volumeAbove(sv);

        uint percent = Constant.PCNT_100;

        if (AboveAmt >= _hardCap) {
            percent =0;
        } else {
            uint remain = _hardCap - AboveAmt;
            if (remain < ownBucketAmt) {
                percent = (remain * Constant.PCNT_100) / ownBucketAmt;
            }
        }

        // Apply a simple reduction factor based on the bucket index. 
        // Bucket 9 to Bucket 0 will reduce chance from 100% to 55%.
        // For simplicity, we do not apply factor for remaing cap and time-left in sale.
        if (percent > 0) {
            uint factor = Constant.PCNT_100 - ((9 - idx) * Constant.PCNT_5);
            percent = (percent * factor)/Constant.PCNT_100;

        }
        return percent;
    }


    function _configFillability(uint hardCap) internal {
        _hardCap = hardCap;
    }

    function _pushFillabilityData(uint sv, uint bought) internal {
        uint idx = _index(sv);
        _buckets[idx] += bought;
    }

    function _index(uint sv) private pure returns (uint idx) {
        idx = sv / 1000e18;
        if (idx > 9) {
            idx = 9;
        }
    }

    function _volumeAbove(uint sv) private view returns (uint AboveAmt, uint ownBucketAmount, uint idx) {

        idx = _index(sv);
        ownBucketAmount = _buckets[idx];
        for (uint n=idx+1; n<=9; n++) {
            AboveAmt += _buckets[n];
        }
    }
}
