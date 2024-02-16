// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 amountToMint
    ) ERC20(_name, _symbol) {
        mint(msg.sender, amountToMint);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
