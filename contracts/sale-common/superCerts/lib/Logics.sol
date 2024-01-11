// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "../CertsTypes.sol";
import "../../../Constant.sol";

library Logics {
    
    event AppendGroup(address indexed user, string name);
    event AttachToCampaign(address campaign, string name);
    event AttachFromCampaign(address campaign, string name);
    event SetGroupFinalized(address indexed user, string name);
    event DefineVesting();
    event StartVesting(address indexed user, uint timeStamp);
    event SetAssetDetails(address indexed user, address tokenAddress);

    //--------------//
    // GROUPS LOGIC //
    //--------------//

    function appendGroups(CertsTypes.Cert storage cert, string[] memory names) external returns (uint len) {
        len = names.length;
        for (uint n = 0; n < len; n++) {
            (bool found, ) = exist(cert, names[n]);
            _require(!found, "Group exist");

            CertsTypes.Group storage newGroup = cert.items.push();
            newGroup.name = names[n];
            emit AppendGroup(msg.sender, names[n]);
        }
    }

    function attachFromCampaign(CertsTypes.Group storage group, address campaign, bool finalizeGroup) external {
        // Check is the campaign hook?
        _require(group.campaignSource == campaign, "Wrong hook");

        if (finalizeGroup) {
            setFinalized(group);
        }
        emit AttachFromCampaign(msg.sender, group.name);
    }

    // Can only be attached to a single campaign only.
    function attachToCampaign(CertsTypes.Cert storage cert, address campaign, uint groupId, string memory groupName) external {
        _require(campaign != Constant.ZERO, "Invalid address");
        
        CertsTypes.Group storage group = at(cert, groupId, groupName);
        _require(group.campaignSource == Constant.ZERO, "Already attached");
        group.campaignSource = campaign; // Attach
        emit AttachToCampaign(campaign, group.name);
    }

    function setFinalized(CertsTypes.Group storage group) public {
        _require(group.campaignSource != Constant.ZERO, "No campaign atached yet");
        _require(group.vestItems.length > 0, "No vesting");
        group.finalized = true;
        emit SetGroupFinalized(msg.sender, group.name);
    }

    function statusCheck(CertsTypes.Cert storage cert, uint groupId) external view returns (CertsTypes.GroupError) {
        uint len = cert.items.length;
        if (groupId >= len) return CertsTypes.GroupError.InvalidId;

        CertsTypes.Group storage group = cert.items[groupId];
        if (!group.finalized) return CertsTypes.GroupError.NotYetFinalized;
        if (group.campaignSource == Constant.ZERO) return CertsTypes.GroupError.NoCampaignSource;
        if (group.vestItems.length == 0) return CertsTypes.GroupError.NoVestingItem;
        return CertsTypes.GroupError.None;
    }

    function exist(CertsTypes.Cert storage cert, string memory name) public view returns (bool, uint) {
        uint len = cert.items.length;
        for (uint n = 0; n < len; n++) {
            if (_strcmp(cert.items[n].name, name)) {
                return (true, n);
            }
        }
        return (false, 0);
    }

    function at(CertsTypes.Cert storage cert, uint groupId, string memory groupName, bool requiredFinalizeState) external view returns (CertsTypes.Group storage group) {
        group = at(cert, groupId, groupName);
        _require(group.finalized == requiredFinalizeState, "Wrong state");
    }

    function at(CertsTypes.Cert storage cert, uint groupId, string memory groupName) public view returns (CertsTypes.Group storage group) {
        group = cert.items[groupId];
        bool matched = _strcmp(group.name, groupName);
        _require(matched, "Unnmatched");
    }

    //---------------//
    // VESTING LOGIC //
    //---------------//

    function defineVesting(CertsTypes.Group storage group, CertsTypes.VestingItem[] calldata vestItems) external returns (uint) {
        uint len = vestItems.length;
        delete group.vestItems; // Clear existing vesting items

        // Append items
        uint totalPercent;
        for (uint n = 0; n < len; n++) {
            CertsTypes.VestingReleaseType relType = vestItems[n].releaseType;

            _require(relType < CertsTypes.VestingReleaseType.Unsupported, "Invalid type");
            _require(!(relType == CertsTypes.VestingReleaseType.Linear && vestItems[n].duration == 0), "Invalid param");
            _require(vestItems[n].percent > 0, "Invalid percent");

            totalPercent += vestItems[n].percent;
            group.vestItems.push(vestItems[n]);
        }
        // The total percent have to add up to 100 %
        _require(totalPercent == Constant.PCNT_100, "Must be 100%");

        emit DefineVesting();

        return len;
    }

    function getClaimablePercent(CertsTypes.Cert storage cert, uint groupId) public view returns (uint claimablePercent, uint totalEntitlement) {
        CertsTypes.Group storage group = cert.items[groupId];
    
        if (!group.finalized) {
            return (0, 0);
        }

        totalEntitlement = group.totalEntitlement;
        uint start = cert.vestingStartTime;
        uint end = block.timestamp;

        // Vesting not started yet ?
        if (start == 0 || end <= start) {
            return (0, totalEntitlement);
        }

        CertsTypes.VestingItem[] storage items = group.vestItems;
        uint len = items.length;

        for (uint n = 0; n < len; n++) {
            (uint percent, bool continueNext, uint traverseBy) = getRelease(items[n], start, end);
            claimablePercent += percent;

            if (continueNext) {
                start += traverseBy;
            } else {
                break;
            }
        }
    }

    function getClaimable(CertsTypes.Cert storage cert, CertsTypes.NftInfo storage nft) external view returns (uint claimable) {
        (uint percentReleasable, ) = getClaimablePercent(cert, nft.groupId);
        if (percentReleasable > 0) {
            uint totalReleasable = (percentReleasable * nft.totalEntitlement) / Constant.PCNT_100;
            if (totalReleasable > nft.totalClaimed) {
                claimable = totalReleasable - nft.totalClaimed;
            }
        }
    }

    function getRelease(CertsTypes.VestingItem storage item, uint start, uint end) public view returns (uint releasedPercent, bool continueNext, uint traverseBy) {
        releasedPercent = 0;
        bool passedDelay = (end > (start + item.delay));
        if (passedDelay) {
            if (item.releaseType == CertsTypes.VestingReleaseType.LumpSum) {
                releasedPercent = item.percent;
                continueNext = true;
                traverseBy = item.delay;
            } else if (item.releaseType == CertsTypes.VestingReleaseType.Linear) {
                uint elapsed = end - start - item.delay;
                releasedPercent = _min(item.percent, (item.percent * elapsed) / item.duration);
                continueNext = (end > (start + item.delay + item.duration));
                traverseBy = (item.delay + item.duration);
            } else {
                assert(false);
            }
        }
    }

    function startVesting(CertsTypes.Cert storage cert, uint startTime) external {
        if (startTime == 0) {
            startTime = block.timestamp;
        }

        // Make sure that the asset address are set before start vesting.
        // Also, at least 1 group must be funded
        CertsTypes.Asset storage asset = cert.asset;
        _require(asset.tokenAddress != Constant.ZERO && startTime >= block.timestamp, "Cannot start");

        cert.vestingStartTime = startTime;
        emit StartVesting(msg.sender, startTime);
    }

    function getUnClaimed(CertsTypes.Cert storage cert, uint groupId) external view returns(uint) {
        
        CertsTypes.Group storage group = cert.items[groupId];
        return group.totalEntitlement - group.totalClaimed;
    }

    //------------//
    // MISC LOGIC //
    //------------//

    function setAssetDetails(CertsTypes.Asset storage asset, address tokenAddress) external {
        _require(tokenAddress != Constant.ZERO, "Invalid address");
        asset.tokenAddress = tokenAddress;
        emit SetAssetDetails(msg.sender, tokenAddress);
    }

    // Helpers
    function _strcmp(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }

    function _require(bool condition, string memory error) private pure {
        require(condition, error);
    }
}
