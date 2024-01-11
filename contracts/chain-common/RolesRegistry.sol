// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;


import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "../interfaces/IRoles.sol";

contract RolesRegistry is IRoles, AccessControlEnumerable {

    bytes32 private constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    bytes32 private constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 private constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
    bytes32 private constant TALLY_ROLE = keccak256("TALLY_ROLE");
    
    event SetRoleRegistry(bytes32 role, address user, string state);

    constructor()  {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    //--------------------//
    // EXTERNAL FUNCTIONS //
    //--------------------//
    
    function setDeployer(address user, bool on) external {
        _setRole(DEPLOYER_ROLE, user, on);
    }
    
    function setConfigurator(address user, bool on) external {
        _setRole(CONFIGURATOR_ROLE, user, on);
    }
    
    function setApprover(address user, bool on) external {
        _setRole(APPROVER_ROLE, user, on);
    }

     function setTallyHandler(address user, bool on) external {
        _setRole(TALLY_ROLE, user, on);
    }
    
    function setRole(string memory roleName, address user, bool on) external {
         bytes32  role = keccak256(abi.encodePacked(roleName));
        _setRole(role, user, on);
    }
    
    
    //------------------------//
    // IMPLEMENTS IRoleAccess //
    //------------------------//
    
    function isAdmin(address user) view override external returns (bool) {
         return hasRole(DEFAULT_ADMIN_ROLE, user);
    }
    
    function isDeployer(address user) view override external returns (bool) {
        return hasRole(DEPLOYER_ROLE, user);
    }
    
    function isConfigurator(address user) view override external returns (bool) {
        return hasRole(CONFIGURATOR_ROLE, user);
    }
    
    function isApprover(address user) view override external returns (bool) {
        return hasRole(APPROVER_ROLE, user);
    }
    
    function isTallyHandler(address user) view override external returns (bool) {
        return hasRole(TALLY_ROLE, user);
    }
    
    function isRole(string memory roleName, address user) view override external returns (bool) {
        return hasRole(keccak256(abi.encodePacked(roleName)), user);
    }

    //--------------------//
    // PRIVATE FUNCTIONS  //
    //--------------------//
    
    function _setRole(bytes32 role, address user, bool on) private {
        
        if (on != hasRole(role, user)) {
            if (on) {
                grantRole(role, user); // Only admin can grant role in OpenZeppelin
                emit SetRoleRegistry(role, user, "Grant Role");
            } else {
                revokeRole(role, user); // Only admin can revoke role in OpenZeppelin
                emit SetRoleRegistry(role, user, "Revoke Role");
            }
        }
    }
}