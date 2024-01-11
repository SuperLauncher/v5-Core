// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "../interfaces/IManager.sol";

abstract contract Factory {
    
    IManager internal _manager;
    uint internal _autoIndex;

    constructor(IManager manager) {
        _manager = manager;
    }

    function create(string calldata symbol) external {
        if (_manager.getRoles().isDeployer(msg.sender)) {
            address dao = _manager.getDaoMultiSig();
            bytes32 salt = keccak256(abi.encodePacked(_autoIndex++, symbol, dao, msg.sender));
            address newAddress = _create(salt, symbol);
            _manager.addEntry(newAddress, dao);
        }
    }

    function _create(bytes32 salt, string calldata symbol) internal virtual returns (address newContract);
}



  
