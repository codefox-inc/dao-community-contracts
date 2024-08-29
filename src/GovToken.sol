// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/// @custom:security-contact dev@codefox.co.jp
contract GovToken is ERC20, ERC20Burnable, AccessControl, ERC20Permit, ERC20Votes {
    error TokenTransferNotAllowed();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(string memory name, string memory symbol, address defaultAdmin, address minter, address burner)
        ERC20(name, symbol)
        ERC20Permit(name)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(BURNER_ROLE, burner);
    }

    // The following functions are overrides required by Solidity.
    /// @dev this function is intentionally made this way to not allow token transfer
    /// @dev instead minting and burning is allowed
    /// @dev added this function to the original contract
    ///
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        // Only allow minting and burning.
        // No token transfer allowed
        if (from != address(0) && to != address(0)) {
            revert TokenTransferNotAllowed();
        }
        super._update(from, to, value);
    }

    /**
     * @notice Burns a specific amount of tokens from a specified account.
     * @dev This function can only be called by accounts with the BURNER_ROLE.
     * @dev added this function to the original contract
     * @param account The address from which the tokens will be burned.
     * @param amount The amount of tokens to burn.
     */
    function burnByBurner(address account, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(account, amount);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
