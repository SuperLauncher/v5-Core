// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../../base/Controllable.sol";

interface ICerts is IERC721 {
    function getClaimable(uint id) external view returns (bool, uint, uint, uint, uint, uint);
}

contract SuperCertsReturnVault is ERC721Holder, Controllable {

    ICerts public immutable superCert;
 
    mapping(address => uint) public entitlementMap;
    address[] public allDepositors;

    uint public totalCertsDeposited;
    uint public totalEntitlementDeposited;
    bool public paused;
 
    event Deposit(address indexed user, uint id, uint entitlement);
    event Pause(bool set);

    constructor(ICerts cert) {
        superCert = cert;
    }

    function deposit(uint id) external {
        require(!paused, "Paused");

        superCert.safeTransferFrom(msg.sender, address(this), id);

        (bool valid, , , , , uint entitlement) = superCert.getClaimable(id);
        require(valid && entitlement  > 0, "Invalid NFT or no entitlement");

        // New address ?
        if (entitlementMap[msg.sender] == 0) {
            allDepositors.push(msg.sender);
        }

        entitlementMap[msg.sender] += entitlement;
        totalCertsDeposited++;
        totalEntitlementDeposited += entitlement;

        emit Deposit(msg.sender, id, entitlement);
    }
   
    function setPause(bool set) external onlyController {

        paused = set;
        emit Pause(set);
    }

     function exportAll() external onlyController view returns (uint, address[] memory, uint[] memory) {

        uint len =  allDepositors.length;
        address[] memory add = new address[](len);
        uint[] memory amounts = new uint[](len);

        address tmp;
        for (uint n = 0; n < len; n++) {
            tmp = allDepositors[n];
            add[n] = tmp;
            amounts[n] = entitlementMap[tmp];
        }
        return (len, add, amounts);
    }

     function export(uint from, uint to) external onlyController view returns (uint, address[] memory, uint[] memory) {
        
        uint len =  allDepositors.length;
        require(len > 0  && from <= to, "Invalid range");
        require(to < len, "Out of range");

        uint count = to - from + 1;

        address[] memory add = new address[](count);
        uint[] memory amounts = new uint[](count);

        address tmp;
        for (uint n = 0; n < count; n++) {
            tmp = allDepositors[n + from];
            add[n] = tmp;
            amounts[n] = entitlementMap[tmp];
        }
        return (count, add, amounts);
    }
}
