// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Constant.sol";


contract Controllable is Ownable {

    address public controller;

    modifier onlyController() {
        require(msg.sender == controller, "Not controller");
        _;
    }

    event ChangeController(address oldAddress, address newAddress);

    constructor() Ownable(msg.sender) {

    }

    function changeController(address newController) public onlyOwner {
        require(newController != Constant.ZERO, "Invalid Address");
        emit ChangeController(controller, newController);
        controller = newController;
    }
}
