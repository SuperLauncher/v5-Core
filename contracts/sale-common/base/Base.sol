// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../../base/Accessable.sol";
import "../../base/MultiSigWithdrawable.sol";
import "../../base/SuperCertsClaimable.sol";
import "../../base/PauseReturnable.sol";
import "../../base/Insurable.sol";
import "../interfaces/IManager.sol";
import "../../Constant.sol";

abstract contract Base is Insurable, PauseReturnable, SuperCertsClaimable, MultiSigWithdrawable, Accessable, ReentrancyGuard {

    using SafeERC20 for IERC20;

     enum State {
        Configured,
        Finalized,
        Tallied,
        Tge,
        Failed
    }

    IManager internal immutable _manager;
    uint internal _state; // Bitmask of bool //

    modifier onlyManager() {
        _require(msg.sender == address(_manager), "Not manager");
        _;
    }

    modifier canConfigure() {
        _require(_manager.getRoles().isConfigurator(msg.sender) && !getState(State.Finalized), "Cannot configure");
        _;
    }

    event Setup(address indexed executor);
    event Finalized(address indexed executor);
    event Tallied(address indexed executor, bytes32 root);
    event Tge(address indexed executor);
    event Failed();

    constructor(IManager mgr) Accessable(mgr.getRoles())
    {
        _manager = mgr;
    }

    function setupCerts(address certsAddress, uint groupId, string memory groupName) external canConfigure {
        _requireNonZero(certsAddress);
        _setupCerts(certsAddress, groupId, groupName);
    }

    function setPause(bool set) public onlyApprover {
        _setPause(set);
    }

    function setReturnFund() public onlyApprover {
        _setReturnable(true);
        emit Failed();
    }

    function getState(State s) public view returns (bool) {
        return (_state & (1 << uint8(s))) > 0;
    }

    function isConfigured() internal view returns (bool) {
        return (getState(State.Configured));
    }

    function isTallied() internal view returns (bool) {
        return (getState(State.Tallied));
    }

    function isTge() internal view returns (bool) {
        return (getState(State.Tge));
    }

    // INTERNAL FUNCTIONS
    function finalize() external onlyApprover {
 
        (, bool enabled) = getCertsInfo();
        _require(enabled && !getState(State.Finalized), "Cannot finalize");
        _setState(State.Finalized, true);
    }

    function multiSigWithdrawToken(address token, uint amount) external onlyDaoAdmin {
        _multiSigWithdrawToken(token, amount, msg.sender);
    }

    function _setState(State state, bool on) internal {
        if (on) {
            _state |= (1 << uint8(state));
        } else {
            _state &= ~(1 << uint8(state));
        }
    }

    function _requireTally(bool state) internal view {
        _require(state == getState(State.Tallied), "Wrong finish state");
    }

    function _requireTge(bool state) internal view {
        _require(state == getState(State.Tge), "Wrong Tge state");
    }

    function _requireNonZero(uint a) internal pure {
        _require (a > 0, "Cannot be 0");
    }

    function _requireNonZero(uint a, uint b) internal pure {
        _require (a > 0 && b > 0, "Cannot be 0");
    }

    function _requireNonZero(address a) internal pure {
        _require (a != Constant.ZERO, "Invalid address");
    }
     function _requireNonZero(address a, address b) internal pure {
        _require (a != Constant.ZERO && b != Constant.ZERO, "Invalid addresses");
    }

    function _min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

