// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../../base/Accessable.sol";
import "./lib/Logics.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract CertsBase is Accessable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Logics for *;

    CertsTypes.Store private _dataStore;
    IManager internal immutable _manager;

    modifier notLive() {
        _require(!isLive(), "Already live");
        _;
    }

    event ClaimCerts(address indexed user, uint timeStamp, uint groupId, uint amount, uint nftId);
    event ClaimTokens(address indexed user, uint timeStamp, uint id, uint amount);
    event Split(uint timeStamp, uint id1, uint id2, uint amount);
    event SplitPercent(uint timeStamp, uint id1, uint id2, uint percent);
    event Combine(uint timeStamp, uint id1, uint id2);

    constructor(IManager mgr) Accessable(mgr.getRoles()) {
        _manager = mgr;
    }

    //--------------------//
    //   QUERY FUNCTIONS  //
    //--------------------//

    function getAsset() external view returns (string memory, string memory) {
        CertsTypes.Asset storage asset = _asset();
        return (asset.symbol, asset.certsName);
    }

    function getGroupCount() external view returns (uint) {
        return _cert().items.length;
    }

    function _getGroup(uint groupId) internal view returns (CertsTypes.Group storage) {
        return _dataStore.cert.items[groupId];
    }

    function getGroupInfo(uint groupId) external view returns (string memory, uint, uint) {
        CertsTypes.Group storage group = _cert().items[groupId];
        return (group.name, group.totalEntitlement, group.totalClaimed);
    }

    function isGroupFinalized(uint groupId) external view returns (bool finalized) {
        return _getGroup(groupId).finalized;
    }

    function checkGroupStatus(uint groupId) external view returns (CertsTypes.GroupError) {
        return _cert().statusCheck(groupId);
    }


    function getVestingInfo(uint groupId) external view returns (CertsTypes.VestingItem[] memory) {
        return _cert().items[groupId].vestItems;
    }

    function getVestingStartTime() public view returns (uint) {
        return _cert().vestingStartTime;
    }

    function getNftInfo(uint nftId) external view returns (uint, uint, uint, bool) {
        CertsTypes.NftInfo storage info = _nftAt(nftId);
        return (info.groupId, info.totalEntitlement, info.totalClaimed, info.valid);
    }

    function isLive() public view returns (bool) {
        uint time = getVestingStartTime();
        return (time != 0 && block.timestamp > time);
    }

    //--------------------//
    // INTERNAL FUNCTIONS //
    //--------------------//
    function _store() internal view returns (CertsTypes.Store storage) {
        return _dataStore;
    }

    function _cert() internal view returns (CertsTypes.Cert storage) {
        return _dataStore.cert;
    }

    function _asset() internal view returns (CertsTypes.Asset storage) {
        return _dataStore.cert.asset;
    }

    function _nftAt(uint nftId) internal view returns (CertsTypes.NftInfo storage nft) {
        nft = _dataStore.nftInfoMap[nftId];
        _require(nft.valid, "Not valid");
    }

    function _nextNftIdIncrement() internal returns (uint) {
        return _dataStore.nextIds++;
    }

    function _transferAssetOut(address to, uint amount) internal {
        address token = _asset().tokenAddress;
        IERC20(token).safeTransfer(to, amount);
    }

    function _requireNonZero(address a) internal pure {
        _require(a != Constant.ZERO, "Invalid address");
    }
}
