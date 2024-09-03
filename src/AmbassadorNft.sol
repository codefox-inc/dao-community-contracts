// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

/// @custom:security-contact dev@codefox.co.jp
// Made by OpenZeppelin Contracts Wizard: https://zpl.in/wizard
contract AmbassadorNft is ERC1155, AccessControl, ERC1155Burnable {
    error DefaultAdminCannotBeZero();

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @dev Initializes the contract by setting the roles, which including the DEFAULT_ADMIN_ROLE, MINTER_ROLE, BURNER_ROLE, and URI_SETTER_ROLE.
    constructor(address defaultAdmin, address minter, address burner, address uriSetter) ERC1155("") {
        if (defaultAdmin == address(0)) revert DefaultAdminCannotBeZero();
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(BURNER_ROLE, burner);
        _grantRole(URI_SETTER_ROLE, uriSetter);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

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

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
