// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

/// @custom:security-contact dev@codefox.co.jp
// Made by OpenZeppelin Contracts Wizard: https://zpl.in/wizard
contract AmbassadorNft is ERC1155, AccessControl, ERC1155Burnable {
    error DefaultAdminCannotBeZero();

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @dev Initializes the contract by setting the roles, which including the DEFAULT_ADMIN_ROLE, MINTER_ROLE, BURNER_ROLE, and URI_SETTER_ROLE.
    /// @param defaultAdmin The address of the default admin.
    /// @param minter The address of the minter.
    /// @param burner The address of the burner.
    /// @param uriSetter The address of the URI setter.
    constructor(address defaultAdmin, address minter, address burner, address uriSetter) ERC1155("") {
        if (defaultAdmin == address(0)) revert DefaultAdminCannotBeZero();
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(BURNER_ROLE, burner);
        _grantRole(URI_SETTER_ROLE, uriSetter);
    }

    /// @notice Set the URI of the token.
    /// @dev This function can only be called by accounts with the URI_SETTER_ROLE.
    /// @param newuri The new URI to set.
    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    /// @notice Mint the token to the specified account.
    /// @dev This function can only be called by accounts with the MINTER_ROLE.
    /// @param account The address to mint the token to.
    /// @param id The id of the token to mint.
    /// @param amount The amount of the token to mint.
    /// @param data Additional data with no specified format.
    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    /// @notice Mint the token to the specified account.
    /// @dev This function can only be called by accounts with the MINTER_ROLE.
    /// @param to The address to mint the token to.
    /// @param ids The ids of the token to mint.
    /// @param amounts The amounts of the token to mint.
    /// @param data Additional data with no specified format.
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @notice Burns some amount of an `id` from `account`.
     * @dev This function can only be called by accounts with the BURNER_ROLE.
     * @dev This function is added to allow the burning of a token with a specific id.
     * @param account Address of the token holder.
     * @param id Identifier of the token.
     */
    function burn(address account, uint256 id, uint256 amount) public override onlyRole(BURNER_ROLE) {
        _burn(account, id, amount);
    }

    /// @notice Batch burning is not supported.
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values)
        public
        virtual
        override
        onlyRole(BURNER_ROLE)
    {
        _burnBatch(account, ids, values);
    }

    /// @notice Check if the contract supports the interface.
    /// @dev This function is required by Solidity.
    /// @param interfaceId The interface ID to check.
    /// @return True if the interface is supported, false otherwise.
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
