// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title NXTU Token
 * @notice The contract is written for the NXTU token.
 * @dev This contract complies with ERC standards.
 * More details on https://eips.ethereum.org/EIPS/eip-20
 * @custom:security support@4nextunicorn.com
 */
contract NxtuToken is ERC20, ERC20Burnable, Ownable {
    /**
     * @notice This function only works once at start up
     * @param initialSupply The amount to be minted for the initial supply.
     */
    constructor(uint256 initialSupply) ERC20("4 Next Unicorn", "NXTU") {
        _mint(_msgSender(), initialSupply);
    }

    /**
     * @notice This function increases the total supply
     * @dev Creates `amount` tokens and assigns them to `account`.
     * @param to The address to which the token will be sent.
     * @param amount The amount to be minted.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * @dev For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * @return The decimals of token
     */
    function decimals() public pure override returns (uint8) {
        return 8;
    }
}
