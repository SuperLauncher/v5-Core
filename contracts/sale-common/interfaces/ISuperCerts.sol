// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

interface ISuperCerts {

    function attachFromCampaign(uint groupId, string memory groupName,  bool finalizeGroup) external ;
    function claimCertsFromCampaign(address user, uint groupId, string memory groupName, uint amount) external;
    function getAssetAddress() external view returns (address);
}

