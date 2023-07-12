// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is ERC20, ERC20Burnable {
    constructor(uint256 amount) ERC20("NXTU", "4 Next Unicorn") {
        _mint(msg.sender, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }
}
