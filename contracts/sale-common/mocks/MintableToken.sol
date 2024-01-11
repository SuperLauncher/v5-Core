// SPDX-License-Identifier: agpl-3.0


pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MintableToken is ERC20 {
    using Math for uint256;

	uint8 _dp = 18;
    constructor(string memory name, string memory symbol, uint8 dp) ERC20(name, symbol) {
		_dp = dp;
    }

	/**
     * @dev - Override _mint
     */
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }


    function mintTo(address to, uint256 amount) external {
        _mint(to, amount);
    }


	/**
     * @dev - Override decimals
     */
	function decimals() public view virtual override returns (uint8) {
        return _dp;
    }
}