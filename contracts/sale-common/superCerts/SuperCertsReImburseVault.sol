// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../../base/Controllable.sol";


contract SuperCertsReImburseVault is Controllable {

    using SafeERC20 for IERC20;

    IERC20 public immutable launchToken;
    bytes32 public merkleRoot;
    bool public paused;

    mapping(address => bool) public claimMap;
 
    event ReImburse(address indexed user, uint id, uint amount);
    event Pause(bool set);
    event EmergencyWithdrawToken(address token, uint amount, address to);

    constructor(IERC20 launch) {
        launchToken = launch;
    }

    function setMerkleRoot(bytes32 root) external onlyController {
        require(root != 0, "Invalid");
        require(merkleRoot == 0, "Already set");
        merkleRoot = root;
    }

    function claimReImbursement(uint id, uint amount, bytes32[] calldata merkleProofs) external {
        require(!paused, "Paused");

        require(!claimMap[msg.sender], "Already claimed");
        claimMap[msg.sender] = true;

        bool ok = _verifyClaim(id, msg.sender, amount, merkleProofs);
        require(ok, "No proofs");
   
        launchToken.safeTransfer(msg.sender, amount); 

        emit ReImburse(msg.sender, id, amount);
    }
   
    function setPause(bool set) external onlyController {
        paused = set;
        emit Pause(set);
    }

    function emergencyWithdrawToken(address token, uint amount, address to) external onlyOwner {
        IERC20(token).safeTransfer(to, amount); 
        emit EmergencyWithdrawToken(token, amount, to);
    }

    function _verifyClaim(uint id, address user, uint amount, bytes32[] calldata merkleProofs) private view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(id, user, amount));
        return MerkleProof.verify(merkleProofs, merkleRoot, node);
    }
}
