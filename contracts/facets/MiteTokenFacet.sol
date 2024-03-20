// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MiteTokenFacet is ERC20, ERC20Permit {
    constructor() ERC20("MiteToken", "MTK") ERC20Permit("MiteToken") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
