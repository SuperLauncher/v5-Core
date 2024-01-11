// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "../interfaces/IManager.sol";
import "../../interfaces/IRoles.sol";
import "../../interfaces/IDataLog.sol";
import "../../Constant.sol";

contract Manager is IManager {

    IRoles internal _roles;
    IDataLog internal _logger;
    address public daoMultiSig;
    address public officialSigner;
    
    modifier onlyFactory() {
        require(_factoryMap[msg.sender], "Not Factory");
        _;
    }
    
    modifier onlyAdmin() {
        require(_roles.isAdmin(msg.sender), "Not Admin");
        _;
    }
    
    // Events
    event FactoryRegistered(address indexed deployedAddress);
    event DaoChanged(address oldDao, address newDao);
    event OfficialSignerChanged(address oldSigner, address newSigner);
    event EntryAdded(address indexed contractAddress, address indexed projectOwner);
    
    struct CampaignInfo {
        address contractAddress;
        address owner;
    }
    
    // History & list of factories.
    mapping(address => bool) private _factoryMap;
    address[] private _factories;
    
    // History/list of all IDOs
    mapping(uint => CampaignInfo) internal _indexCampaignMap; // Starts from 1. Zero is invalid //
    mapping(address => uint) internal _addressIndexMap;  // Maps a campaign address to an index in _indexCampaignMap.
    uint internal _count;
    
    constructor(IRoles roles,  IDataLog logger, address dao, address signer) 
    {
        require(dao != Constant.ZERO && signer != Constant.ZERO, "Invalid address");
        _roles = roles;
        _logger = logger;
        daoMultiSig = dao;
        officialSigner = signer;
    }
    
    // EXTERNAL FUNCTIONS
    function getCampaignInfo(uint id) external view returns (CampaignInfo memory) {
        return _indexCampaignMap[id];
    }
    
    function getTotalCampaigns() external view returns (uint) {
        return _count;
    }
    
    function registerFactory(address newFactory) external onlyAdmin {
        if ( _factoryMap[newFactory] == false) {
            _factoryMap[newFactory] = true;
            _factories.push(newFactory);
            emit FactoryRegistered(newFactory);
        }
    }

    function setDaoMultiSig(address newDao) external onlyAdmin {
        if (newDao != Constant.ZERO && newDao != daoMultiSig) {
            emit DaoChanged(daoMultiSig, newDao);
            daoMultiSig = newDao;
        }
    }

    function setOfficialSigner(address newSigner) external onlyAdmin {
        if (newSigner != Constant.ZERO && newSigner != officialSigner) {
            emit OfficialSignerChanged(officialSigner, newSigner);
            officialSigner = newSigner;
        }
    }

    function isFactory(address contractAddress) external view returns (bool) {
        return _factoryMap[contractAddress];
    }
    
    function getFactory(uint id) external view returns (address) {
        return ((id < _factories.length) ? _factories[id] : Constant.ZERO );
    }

    // IMPLEMENTS IManager
    function getRoles() external view override returns (IRoles) {
        return _roles;
    }

    function getDaoMultiSig() external override view returns (address) {
        return daoMultiSig;
    }

     function getOfficialSigner() external override view returns (address) {
        return officialSigner;
    }

    function logData(address user, DataSource source, DataAction action, uint data1, uint data2) external override {

        // From an official campaign ?
        uint id = _addressIndexMap[msg.sender];
        require(id > 0, "Invalid camapign");   

        _logger.log(msg.sender, user, uint(source), uint(action), data1, data2);
    }

    function addEntry(address newContract, address owner) external override onlyFactory {
        _count++;
        _indexCampaignMap[_count] = CampaignInfo(newContract, owner);
        _addressIndexMap[newContract] = _count;
        emit EntryAdded(newContract, owner);
    }
}

