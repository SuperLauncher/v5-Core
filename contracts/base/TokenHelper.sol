// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../Constant.sol";


contract TokenHelper {

    using SafeERC20 for IERC20;

    function _transferTokenIn(address token, uint amount) internal {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount); 
    }

    function _transferTokenOut(address token, uint amount, address to) internal  {
        IERC20(token).safeTransfer(to, amount); 
    }

    function _transferTokenFrom(address token, uint amount, address from, address to) internal {
        IERC20(token).safeTransferFrom(from, to, amount); 
    }

    function _burnTokenFrom(address token, address from, uint amount) internal {
        if (amount > 0) {
            ERC20Burnable(token).burnFrom(from, amount);
        }
    }

    function _burnToken(address token, uint amount) internal {
        if (amount > 0) {
            ERC20Burnable(token).burn(amount);
        }
    }
    function _getDpValue(address token) internal view returns (uint) {
        try IERC20Metadata(token).decimals() returns (uint8 dp) {
            return 10 ** dp;
        } catch {
            return 1e18;
        }
    }
}

