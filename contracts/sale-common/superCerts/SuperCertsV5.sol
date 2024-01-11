// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interfaces/ISuperCerts.sol";
import "./CertsBase.sol";

// Note: Support for tokens only. 
// For NFT project, these should not have any vesting and should be distributed by project.
contract SuperCertsV5 is ISuperCerts, ERC721Enumerable, CertsBase {
    using SafeERC20 for IERC20;
    using Logics for *;

    string private constant SUPER_CERTS = "SuperCerts";
    string private constant BASE_URI = "https://superlauncher.io/metadata/";

    constructor(
        IManager manager,
        string memory tokenSymbol,
        string memory certsName
    ) ERC721(certsName, SUPER_CERTS) CertsBase(manager) {
        _asset().symbol = tokenSymbol;
        _asset().certsName = certsName;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    function tokenURI(uint /*tokenId*/) public view virtual override returns (string memory) {
        return string(abi.encodePacked(BASE_URI, _asset().certsName));
    }

    //--------------------//
    //   SETUP & CONFIG   //
    //--------------------//

    function appendGroups(string[] memory names) external notLive onlyConfigurator {
        _cert().appendGroups(names);
    }

    function defineVesting(uint groupId, string memory groupName, CertsTypes.VestingItem[] calldata vestItems) external notLive onlyConfigurator {
        CertsTypes.Group storage group = _cert().at(groupId, groupName, false);
        group.defineVesting(vestItems);
    }


    // Allow Ido, Otc  campaign to be user source of this SuperCert
    // Only allow attachment once.
    function attachToCampaign(address campaign, uint groupId, string memory groupName) external notLive onlyConfigurator {
        _cert().attachToCampaign(campaign, groupId, groupName);
    }

   


    function setAssetDetails(address tokenAddress) external notLive onlyConfigurator {
        _asset().setAssetDetails(tokenAddress);
    }

    function setGroupFinalized(uint groupId, string memory groupName) external notLive onlyApprover {
        CertsTypes.Group storage group = _cert().at(groupId, groupName, false);
        group.setFinalized();
    }


    // If startTime is 0, the vesting wil start immediately.
    function startVesting(uint startTime) external notLive onlyApprover {
        _cert().startVesting(startTime);
    }

    //--------------------//
    //   USER OPERATION   //
    //--------------------//


    

    function getGroupReleasable(uint groupId) external view returns (uint percentReleasable, uint totalEntitlement) {
        (percentReleasable, totalEntitlement) = _cert().getClaimablePercent(groupId);
    }

    function getClaimable(uint nftId) public view returns (uint claimable, uint totalClaimed, uint totalEntitlement) {
        CertsTypes.NftInfo storage nft = _nftAt(nftId);
        totalEntitlement = nft.totalEntitlement;
        totalClaimed = nft.totalClaimed;
        claimable = _cert().getClaimable(nft);
    }

    function claimTokens(uint nftId) external nonReentrant {
        _require(ownerOf(nftId) == msg.sender, "Not owner");

        // if this group is not yet funded, it should not be claimable
        CertsTypes.NftInfo storage nft = _nftAt(nftId);
        CertsTypes.Group storage group = _getGroup(nft.groupId);

        (uint claimable, , ) = getClaimable(nftId);
        _require(claimable > 0, "Nothing to claim");

        nft.totalClaimed += claimable;
        group.totalClaimed += claimable;

        _transferAssetOut(msg.sender, claimable);
        
        emit ClaimTokens(msg.sender, block.timestamp, nftId, claimable);
        _manager.logData(msg.sender, DataSource.Campaign, DataAction.ClaimTokens, nftId, claimable);
    }

    // Split an amount of entitlement out from the "remaining" entitlement from an exceeding Deed and becomes a new Deed.
    // After the split, both Deeds should have non-zero remaining entitlement left.
    function split(uint id, uint amount) external nonReentrant returns (uint newId) {
        _require(ownerOf(id) == msg.sender, "Not owner");

        CertsTypes.NftInfo storage nft = _nftAt(id);
        uint entitlementLeft = nft.totalEntitlement - nft.totalClaimed;
        _require(amount > 0 && entitlementLeft > amount, "Invalid amount");

        // Calculate the new NFT's required totalEntitlemnt totalClaimed, in a way that these values are distributed
        // as fairly as possible between the parent and child NFT.
        // Important note is that the sum of the totalEntitlement and totalClaimed before and after the split
        // should remain the same. Nothing more or less is resulted due to the split.
        uint neededTotalEnt = (amount * nft.totalEntitlement) / entitlementLeft;
        _require(neededTotalEnt > 0, "Invalid amount");
        uint neededTotalClaimed = neededTotalEnt - amount;

        nft.totalEntitlement -= neededTotalEnt;
        nft.totalClaimed -= neededTotalClaimed;

        // Sanity Check
        _require(nft.totalEntitlement > 0 && nft.totalClaimed < nft.totalEntitlement, "Fail check");

        // mint new nft
        newId = _mint(msg.sender, nft.groupId, neededTotalEnt, neededTotalClaimed);
        emit Split(block.timestamp, id, newId, amount);
    }

    function combine(uint id1, uint id2) external nonReentrant {
        _require(ownerOf(id1) == msg.sender && ownerOf(id2) == msg.sender, "Not owner");

        CertsTypes.NftInfo storage nft1 = _nftAt(id1);
        CertsTypes.NftInfo memory nft2 = _nftAt(id2);

        // Must be the same group
        _require(nft1.groupId == nft2.groupId, "Different group");

        // Since the vesting items are the same, we can just add up the 2 nft
        nft1.totalEntitlement += nft2.totalEntitlement;
        nft1.totalClaimed += nft2.totalClaimed;

        // Burn NFT 2
        _burn(id2);
        delete _store().nftInfoMap[id2];

        emit Combine(block.timestamp, id1, id2);
    }

    //-------------------//
    // ISuperCert        //
    //-------------------//

     // These are called by the campaign
    function attachFromCampaign(uint groupId, string memory groupName, bool finalizeGroup) external override notLive {
        CertsTypes.Group storage group = _cert().at(groupId, groupName, false);
        group.attachFromCampaign(msg.sender, finalizeGroup);
    }

    function claimCertsFromCampaign(address user, uint groupId, string memory groupName, uint amount) external override nonReentrant {
        
        CertsTypes.Group storage group = _cert().at(groupId, groupName);
        _require(group.finalized, "Not finalized");

        // Only the correct campaign can call this to mint cert
        _require(group.campaignSource == msg.sender && user != Constant.ZERO, "Cannot claim");

        // Mint NFT
        uint nftId = _mint(user, groupId, amount, 0);
        group.totalEntitlement += amount; // Dynamic update of totalEntitlement as users claim certs.

        emit ClaimCerts(user, block.timestamp, groupId, amount, nftId);
        _manager.logData(msg.sender, DataSource.Campaign, DataAction.ClaimCerts, nftId, amount);
    }

    function getAssetAddress() external override view returns (address) {
        return _asset().tokenAddress;
    }

    //-------------------//
    // PRIVATE FUNCTIONS //
    //-------------------//

    function _mint(address to, uint groupId, uint totalEntitlement, uint totalClaimed) private returns (uint id) {
        _require(totalEntitlement > 0, "Invalid entitlement");
        id = _nextNftIdIncrement();
        _mint(to, id);

        // Setup the certificate's info
        _store().nftInfoMap[id] = CertsTypes.NftInfo(groupId, totalEntitlement, totalClaimed, true);
    }
}
