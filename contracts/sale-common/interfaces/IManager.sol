// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "../../interfaces/IRoles.sol";
import "../../interfaces/IDataLog.sol";


interface IManager {
    function getRoles() external view returns (IRoles);
    function getDaoMultiSig() external view returns (address);
    function getOfficialSigner() external view returns (address);
    function logData(address user, DataSource source, DataAction action, uint data1, uint data2) external;
    function addEntry(address newContract, address owner) external;
}

