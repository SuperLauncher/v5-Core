
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "../interfaces/IRoles.sol";
import "../Constant.sol";

contract Accessable {

    IRoles private _roles;

    string private constant NO_RIGHTS = "No rights";

    constructor(IRoles roles) {
        _roles = roles;
    }

    function getRoles() public view returns (IRoles) {
        return _roles;
    }
   
    modifier onlyDeployer() {
        _require(_roles.isDeployer(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyConfigurator() {
        _require(_roles.isConfigurator(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyApprover() {
        _require(_roles.isApprover(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyDaoAdmin() {
        _require(_roles.isAdmin(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyTallyHandler() {
        _require(_roles.isTallyHandler(msg.sender), NO_RIGHTS);
        _;
    }

    function _require(bool condition, string memory err) pure internal {
        require(condition, err);
    }
}