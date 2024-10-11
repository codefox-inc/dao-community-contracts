// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Permit, Nonces} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/// @custom:security-contact dev@codefox.co.jp
contract GovToken is ERC20, ERC20Burnable, AccessControl, ERC20Permit, ERC20Votes {
    error DefaultAdminCannotBeZero();
    error TokenTransferNotAllowed();

    // event added for the change of burnedAmountOfUtilToken
    event burnedAmountOfUtilTokenSet(address indexed account, uint256 amount);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant VOTING_POWER_EXCHANGE_ROLE = keccak256("VOTING_POWER_EXCHANGE_ROLE");

    // added for recording the amount of utility tokens burned by a specific account
    mapping(address account => uint256 burnedAmount) public burnedAmountOfUtilToken;

    constructor(
        string memory name,
        string memory symbol,
        address defaultAdmin,
        address minter,
        address burner,
        address votingPowerExchange
    ) ERC20(name, symbol) ERC20Permit(name) {
        if (defaultAdmin == address(0)) revert DefaultAdminCannotBeZero();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(BURNER_ROLE, burner);
        // votingPowerExchange role is supposed to be only granted to VotingPowerExchange contract
        _grantRole(VOTING_POWER_EXCHANGE_ROLE, votingPowerExchange);
    }

    // The following functions are overrides required by Solidity.
    /// @dev this function is intentionally made this way to not allow token transfer
    /// @dev on the other hand, minting and burning are allowed
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

    /**
     * @notice Sets the amount of utility tokens burned by a specific account.
     * @dev added this function to the original contract
     * @param account The account for which the burned amount is set.
     * @param amount The amount of utility tokens burned.
     */
    function setBurnedAmountOfUtilToken(address account, uint256 amount)
        external
        onlyRole(VOTING_POWER_EXCHANGE_ROLE)
    {
        burnedAmountOfUtilToken[account] = amount;
        emit burnedAmountOfUtilTokenSet(account, amount);
    }

    /**
     * @notice Overrides the clock function to return the current timestamp.
     * @return The current timestamp.
     */
    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    /**
     * @notice Overrides the CLOCK_MODE function to return the current timestamp.
     * @return The current timestamp.
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    /**
     * @notice Overrides the nonces function to return the nonce of the owner.
     * @param owner The address of the owner.
     * @return The nonce of the owner.
     */
    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
