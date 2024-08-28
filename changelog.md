# Smart Contracts' Changelog

## [Unreleased]

### Added

1. ERC20UpgradeableToken (ERC20)

- Created using OpenZeppelin Wizard.
- Created using OpenZeppelin upgradeable contracts.

2. AmbassadorNft (ERC1155)

- Created using OpenZeppelin Wizard.
- Added some roles and the burning function to it.

### More Information

Overall, we changed all the version of solidity into fixed 0.8.24.

1. ERC20UpgradeableToken
   Forked from OpenZeppelin's ERC20 Wizard contract.

- Allow initializing the contract with a name, symbol, and burner. Including the originally generated code by Wizard of pauser, minter, and the default admin roles.
- Modified the contract to add burner access right and burner to burn tokens.

2. AmbassadorNft
   Forked from OpenZeppelin's ERC1155 Wizard contract.

- Added new roles of `burner`, `minter`, `uriSetter`, and `admin` to the contract.
- Allowing setting the URI of the token afterwards.
- Allowing burning of the token by the burner role.

### Fixed

### Removed
