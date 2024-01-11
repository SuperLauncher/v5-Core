// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "../base/Factory.sol";
import "./SalesV5.sol";


contract SalesV5Factory is Factory {
    
    constructor(IManager manager) Factory(manager) { }

    function _create(bytes32 salt, string calldata /*symbol*/) internal override returns (address newContract) {
        return address(new SalesV5{salt: salt}(_manager));
    }
}

