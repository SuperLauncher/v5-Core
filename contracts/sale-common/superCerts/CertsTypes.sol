// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

library CertsTypes {
    struct Store {
        Cert cert;
        mapping(uint => NftInfo) nftInfoMap; // Maps NFT Id to NftInfo
        uint nextIds; // NFT Id management
    }

    struct Asset {
        string symbol;
        string certsName;
        address tokenAddress;
        uint tokenId; // Specific for ERC1155 type of asset only
    }

    struct Cert {
        Asset asset;
        Group[] items;
        uint vestingStartTime; // Global timestamp for vesting to start
    }

    struct Group {
        string name;
        uint totalEntitlement; // Total tokens to be distributed to this group
        uint totalClaimed;
        VestingItem[] vestItems;
        address campaignSource; // This group is attach to a sale campaign contract.
        bool finalized;
    }

    struct VestingItem {
        VestingReleaseType releaseType;
        uint delay;
        uint duration;
        uint percent;
    }

    struct NftInfo {
        uint groupId;
        uint totalEntitlement;
        uint totalClaimed;
        bool valid;
    }

    enum VestingReleaseType {
        LumpSum,
        Linear,
        Unsupported
    }

    enum GroupError {
        None,
        InvalidId,
        NotYetFinalized,
        NoCampaignSource,
        NoVestingItem
    }
}
