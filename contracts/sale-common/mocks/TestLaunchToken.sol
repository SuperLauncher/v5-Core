// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestLaunch is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("TestLaunch", "Launch") Ownable(msg.sender) {

        mint(msg.sender, 1_000_000e18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
