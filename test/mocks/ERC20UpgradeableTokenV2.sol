// SPDX-License-Identifier: BUSL-1.1
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

import "src/ERC20UpgradeableTokenV1.sol";

/// @custom:oz-upgrades-from ERC20UpgradeableTokenV1
contract ERC20UpgradeableTokenV2 is ERC20UpgradeableTokenV1 {
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    address private _treasury; // dummy state variable for testing

    /// @dev Initializes the V2 version of the contract.
    function initializeV2(address treasury, address newAdmin) public reinitializer(2) {
        _grantRole(TREASURY_ROLE, treasury);
        _treasury = treasury;

        // If you need to change the administrator
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    /**
     * @notice Sets a new treasury address.
     * @dev This function can only be called by accounts with the TREASURY_ROLE.
     * @param newTreasury The new treasury address.
     */
    function setTreasury(address newTreasury) public onlyRole(TREASURY_ROLE) {
        _treasury = newTreasury;
    }

    /**
     * @notice Retrieves the current treasury address.
     * @return The current treasury address.
     */
    function getTreasury() public view returns (address) {
        return _treasury;
    }

    // Add more functions or override existing functionality as needed.
}
