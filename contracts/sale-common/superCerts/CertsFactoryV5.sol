// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "../base/Factory.sol";
import "./SuperCertsV5.sol";

contract CertsFactoryV5 is Factory {
   
    constructor(IManager manager) Factory(manager) { }

    function _create(bytes32 salt, string calldata symbol) internal override returns (address newContract) {
        string memory certsName = string(abi.encodePacked(symbol, "-Certs")); // Append symbol from XYZ -> XYZ-Certs
        return address(new SuperCertsV5{salt: salt}(_manager, symbol, certsName));
    }
}
