// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../../base/Controllable.sol";


contract SuperLoyalEra1 is Controllable {

    using SafeERC20 for IERC20;

    IERC20 public immutable launchToken;
    bytes32 public merkleRoot;
    bool public paused;
    uint public immutable expiryTime;

    uint public constant VEST_WINDOW = 90 days;
    uint public constant VEST_DURATION = 365 days;

    struct Reward {
        uint id;
        uint vestStartTime;
        uint total;
        uint totalClaimed;
    }

    mapping(address => Reward) public rewardMap;
 
    event Vest(address indexed user, uint id, uint amount);
    event ClaimReward(address indexed user, uint id, uint amount);
    event Pause(bool set);
    event EmergencyWithdrawToken(address token, uint amount, address to);

    constructor(IERC20 launch) {
        launchToken = launch;
        expiryTime = block.timestamp + VEST_WINDOW;
    }

    function setMerkleRoot(bytes32 root) external onlyController {
        require(root != 0 && merkleRoot == 0, "Invalid or already set");
        merkleRoot = root;
    }

    function vest(uint id, uint numProjectsBought, uint totalBought, uint amountClaimable, bytes32[] calldata merkleProofs) external {
        require(!paused, "Paused");
        require(block.timestamp < expiryTime, "Expired");
        require(amountClaimable > 0, "Nothing to vest");

        Reward storage r = rewardMap[msg.sender];
        require(r.vestStartTime == 0, "Already vested");

        bool ok = _verifyClaim(id, numProjectsBought, totalBought, amountClaimable, msg.sender, merkleProofs);
        require(ok, "No proofs");

        r.id = id;
        r.vestStartTime = block.timestamp;
        r.total = amountClaimable;
   
        emit Vest(msg.sender, id, amountClaimable);
    }

    function claimRewards() external {
        require(!paused, "Paused");

        (uint total, uint available,) = getClaimableRewards(msg.sender);
        require(total > 0, "No reward");

        if (available > 0) {
            Reward storage r = rewardMap[msg.sender];
            r.totalClaimed += available;
            launchToken.safeTransfer(msg.sender, available); 
            emit ClaimReward(msg.sender, r.id, available);
        }
    }

    function getClaimableRewards(address user) public view returns (uint total, uint available, uint claimed) {
        Reward memory r = rewardMap[user];
        total = r.total;
        claimed = r.totalClaimed;

        if (total > 0 && claimed < total) {
            uint _time = block.timestamp;
            if (_time > r.vestStartTime) {
                uint elapsed = _min(_time - r.vestStartTime, VEST_DURATION);
                uint releasable = (total * elapsed) / VEST_DURATION;
                available = releasable - claimed;
            }
        }
    }
   
    function setPause(bool set) external onlyController {
        paused = set;
        emit Pause(set);
    }

    function emergencyWithdrawToken(address token, uint amount, address to) external onlyOwner {
        IERC20(token).safeTransfer(to, amount); 
        emit EmergencyWithdrawToken(token, amount, to);
    }

    function _verifyClaim(uint id, uint numProjectsBought, uint totalBought, uint amountClaimable, address user, bytes32[] calldata merkleProofs) private view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(id, numProjectsBought, totalBought, amountClaimable, user));
        return MerkleProof.verify(merkleProofs, merkleRoot, node);
    }

    function _min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}
