// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "../sale-common/interfaces/ISuperCerts.sol";
import "./TokenHelper.sol";

abstract contract SuperCertsClaimable is TokenHelper {

    struct CertData {
        bool enabled;
        address certsAddress;
        uint groupId;
        string groupName;
        mapping(address=> bool) claimedMap;
    }

    CertData private _data;
    
    function getCertsInfo() public view returns (address certsAddress, bool enabled) {
        certsAddress = _data.certsAddress;
        enabled = _data.enabled;
    }

    function hasClaimedCerts(address user) public view returns (bool) {
        return _data.claimedMap[user];
    }

    function _setupCerts(address certsAddress, uint groupId, string memory groupName) internal {
        _data.enabled = true;
        _data.certsAddress = certsAddress;
        _data.groupId = groupId;
        _data.groupName = groupName;

        // Attach to cert to campaign //
        ISuperCerts(certsAddress).attachFromCampaign(groupId, groupName, true);
    }

    function _isCertsClaimable(address user) internal view returns (bool certsEnabled, bool claimed) {
        certsEnabled = _data.enabled;
        claimed = _data.claimedMap[user];
    }

    function _claimCerts(address user, uint entitlement) internal returns (bool success) {

        if (!_data.enabled || _data.claimedMap[user]) {
            return false;
        }
        _data.claimedMap[user] = true;

        // Transfer the required asset tokens to the cert
        ISuperCerts cert = ISuperCerts(_data.certsAddress);
        address token = cert.getAssetAddress();
        _transferTokenOut(token, entitlement, _data.certsAddress);

        // Allow user to mint the cert
        cert.claimCertsFromCampaign(user, _data.groupId, _data.groupName, entitlement);
        return true;
    }

    function _getAssetTokenAddress() internal view returns (address) {

        bool valid = _data.enabled && _data.certsAddress != Constant.ZERO;
        return valid ? ISuperCerts(_data.certsAddress).getAssetAddress() : Constant.ZERO;
    }
}