// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestSvLaunch is ERC20, Ownable {
    constructor() ERC20("TestSvLaunch", "svLaunch") Ownable(msg.sender) {

        mint(msg.sender, 1_000_000e18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
