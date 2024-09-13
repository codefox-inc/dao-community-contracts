# Smart Contracts for DAO community

This is a repository for the smart contracts of the DAO community. The smart contracts are written in Solidity and tested using the Foundry testing framework.

## Introduction

This is a repository for the smart contracts of the DAO community governance, which is some basic tools for the community.
There are separated tools for the community governance. It will be explained here based on the smart contracts.

All the contracts are sitting in the `src/` folder. These are the core contracts of the protocol.

This repository consists of the following smart contracts:

- AmbassadorNft.sol
  - The smart contract for the NFT that represents the membership of the community.
  - This smart contract is independent from the other smart contracts.
  - The contract is based on the ERC1155 contract of the OpenZeppelin.
- ERC20UpgradeableTokenV1.sol
  - The smart contract for the ERC20 token that is used to represent the utility token of the community.
  - Its use case is to be exchanged for the governance token of the community.
  - Other use cases are possible and it is remained to be defined by the community.
  - The contract is based on the ERC20Upgradeable contract of the OpenZeppelin.
- GovToken.sol
  - The smart contract functioning as the governance token of the community.
  - The token is used to represent the voting power of the holder which is not transferable.
  - The contract is based on the ERC20 contract of the OpenZeppelin.
- VotingPowerExchange.sol
  - The smart contract for the voting power exchange of the community.
  - The contract is used to get the governance token by burning the utility token the user holds.
  - This contract is created from scratch.
- MyGovernor.sol
  - The smart contract for the DAO governance of the community.
  - The contract is used to manage the proposal of the community in a more decentralized manner.
  - The contract is based on the Governor contract of the OpenZeppelin.
- Timelock.sol
  - The smart contract for the timelock of the community.
  - This contract will become the owner of the MyGovernor contract.

## Roles

The system is managed by different roles. The roles are managed by the default admin role.

- DEFAULT_ADMIN_ROLE: The default admin role is the owner of the contract.
  - This is the highest authority role in the contract.
  - Responsibilities: Has the power to manage all other roles.
  - Functions: Can grant and revoke all other roles.
- MANAGER_ROLE:
  - Responsibilities: Can manage the contract and call some special functions.
  - Functions: `setVotingPowerCap()`
- EXCHANGER_ROLE: Exchanger role is the role that can exchange the governance token for the utility token.
  - Responsibilities: Can exchange the governance token for the utility token.
  - Functions: `exchange()`
- MINTER_ROLE: The minter role is the role that can mint new tokens.
  - Responsibilities: Can mint new tokens for the ambassador NFT, the utility token and the governance token.
  - Functions: `mint()`, `mintBatch()`
- BURNER_ROLE: The burner role is the role that can burn the tokens for the ambassador NFT, the utility token and the governance token.
  - Responsibilities: Can burn the tokens.
  - Functions: `burn()`, `burnBatch()`,`burnByBurner()`
- URI_SETTER_ROLE: The URI setter role is the role that can set the URI of the token.
  - Responsibilities: Can set the URI of the token.
  - Functions: `setURI()`
- UPGRADER_ROLE: The upgrader role is the role that can upgrade the contract.
  - Responsibilities: Can upgrade the contract.
  - Functions: `upgradeToAndCall()`

## Smart Contracts

### AmbassadorNft.sol

This is the smart contract for the NFT that represents the membership of the community. I will give some explanation for the possible use cases and the functions of the NFT.

#### Possible use cases and functions explanation

The NFT can be used to represent the membership of the community. For example, membership of A can be represented by NFT1155's id 0 and membership of B can be represented by NFT1155's id 1. Anyone who holds the NFT can be considered as the member of the community.

The default admin role has the right to set the minter and the burner role. The minter role is the role that can mint new tokens. The burner role is the role that can burn the tokens from the specified account.

There are functions to batch mint and batch burn the NFTs. With these functions, the minter and burner roles can easily mint and burn the NFTs for the members.

And the URI of the NFT can be set by the URI setter role after the deployment of the contract.

### ERC20UpgradeableTokenV1.sol

This is the smart contract for the ERC20 token that is used to represent the utility token of the community. This utility token is transferable.

#### Possible use cases and functions explanation

This token is used as the utility token for the community, which can be earned by doing missions or other activities for the community. The users can use utility token to exchange the governance token.

The default admin role has the right to set the minter and the burner role. The minter role is the role that can mint new tokens. The burner role is the role that can burn the tokens from the specified account.

The contract itself is pausable. The pauser role is the role that can pause and unpause the contract. When the contract is paused, the minting and transferring of the token are disabled.

### GovToken.sol

### VotingPowerExchange.sol

### MyGovernor.sol

### Timelock.sol

## About auditing

### Scope

- src/
  - AmbassadorNft.sol
  - ERC20UpgradeableTokenV1.sol
  - GovToken.sol
  - VotingPowerExchange.sol
  - MyGovernor.sol
  - Timelock.sol

### Out of Scope

Any file except for the files in the above Scope.

### Known issues

- Two step ownership transfer process is a known issue. We accept the risk of it.
- The precision loss in the calculation of the voting power and the burned token is existing but the precision loss will not be a problem because the value loss caused by it is very small, e.g. 1e9 token. It is ignorable.

### notes

- Because we are using a mathematical formula(mentioned in the _Reference_ section) which including square root calculation, some precision loss happens in the calculation. e.g. if we exchange 1e9 utility token for the governance token theoretically, what we get is zero token. Because of that, we made the value of the utility token to be 1e18 at least if someone wants to call the `exchange` function.
- Maybe the tests, also fuzz tests, are not able to cover all the edge cases. if you find any issues, please let us know.

## Tests

The tests are written in the `test/` directory. And it consists of the following tests:

- unit tests: `test/unit/`
- integration tests: `test/integration/`
- fuzz tests: `test/fuzz/`

More information about the tests is written in the `test/readme.md`. Please refer to it for more details about the tests.

## How to Start

1. Clone the repository `git clone https://github.com/codefox-inc/dao-community-contracts.git`.
2. Update the foundry dependencies by running `foundryup`.
3. Install the dependencies by running `make install`.
4. Compile the contracts by running `forge compile`.
5. Run the test by running `make test`.
6. Run the coverage by running `make coverage`.

## References

### Documents

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin](https://docs.openzeppelin.com/)

### Mathematical Formula and tables

These are the values we used in the exchange function and tests for voting power <-> burned token calculation.

```
x = (2 \* sqrt(306.25 + 30y) - 5) / 30 - 1
y = (15*x^2+35*x)/2

x: mintedToken
y: burnedToken
```

| Minted Token (lvl) | Level | Burned Token |
| ------------------ | ----- | ------------ |
| 0                  | 1     | 0            |
| 1                  | 2     | 25           |
| 2                  | 3     | 65           |
| 3                  | 4     | 120          |
| 4                  | 5     | 190          |
| 5                  | 6     | 275          |
| 6                  | 7     | 375          |
| 7                  | 8     | 490          |
| 8                  | 9     | 620          |
| 9                  | 10    | 765          |
| 10                 | 11    | 925          |
| 11                 | 12    | 1100         |
| 12                 | 13    | 1290         |
| 13                 | 14    | 1495         |
| 14                 | 15    | 1715         |
| 15                 | 16    | 1950         |
| 16                 | 17    | 2200         |
| 17                 | 18    | 2465         |
| 18                 | 19    | 2745         |
| 19                 | 20    | 3040         |
| 20                 | 21    | 3350         |
| 21                 | 22    | 3675         |
| 22                 | 23    | 4015         |
| 23                 | 24    | 4370         |
| 24                 | 25    | 4740         |
| 25                 | 26    | 5125         |
| 26                 | 27    | 5525         |
| 27                 | 28    | 5940         |
| 28                 | 29    | 6370         |
| 29                 | 30    | 6815         |
| 30                 | 31    | 7275         |
| 31                 | 32    | 7750         |
| 32                 | 33    | 8240         |
| 33                 | 34    | 8745         |
| 34                 | 35    | 9265         |
| 35                 | 36    | 9800         |
| 36                 | 37    | 10350        |
| 37                 | 38    | 10915        |
| 38                 | 39    | 11495        |
| 39                 | 40    | 12090        |
| 40                 | 41    | 12700        |
| 41                 | 42    | 13325        |
| 42                 | 43    | 13965        |
| 43                 | 44    | 14620        |
| 44                 | 45    | 15290        |
| 45                 | 46    | 15975        |
| 46                 | 47    | 16675        |
| 47                 | 48    | 17390        |
| 48                 | 49    | 18120        |
| 49                 | 50    | 18865        |
| 50                 | 51    | 19625        |
| 51                 | 52    | 20400        |
| 52                 | 53    | 21190        |
| 53                 | 54    | 21995        |
| 54                 | 55    | 22815        |
| 55                 | 56    | 23650        |
| 56                 | 57    | 24500        |
| 57                 | 58    | 25365        |
| 58                 | 59    | 26245        |
| 59                 | 60    | 27140        |
| 60                 | 61    | 28050        |
| 61                 | 62    | 28975        |
| 62                 | 63    | 29915        |
| 63                 | 64    | 30870        |
| 64                 | 65    | 31840        |
| 65                 | 66    | 32825        |
| 66                 | 67    | 33825        |
| 67                 | 68    | 34840        |
| 68                 | 69    | 35870        |
| 69                 | 70    | 36915        |
| 70                 | 71    | 37975        |
| 71                 | 72    | 39050        |
| 72                 | 73    | 40140        |
| 73                 | 74    | 41245        |
| 74                 | 75    | 42365        |
| 75                 | 76    | 43500        |
| 76                 | 77    | 44650        |
| 77                 | 78    | 45815        |
| 78                 | 79    | 46995        |
| 79                 | 80    | 48190        |
| 80                 | 81    | 49400        |
| 81                 | 82    | 50625        |
| 82                 | 83    | 51865        |
| 83                 | 84    | 53120        |
| 84                 | 85    | 54390        |
| 85                 | 86    | 55675        |
| 86                 | 87    | 56975        |
| 87                 | 88    | 58290        |
| 88                 | 89    | 59620        |
| 89                 | 90    | 60965        |
| 90                 | 91    | 62325        |
| 91                 | 92    | 63700        |
| 92                 | 93    | 65090        |
| 93                 | 94    | 66495        |
| 94                 | 95    | 67915        |
| 95                 | 96    | 69350        |
| 96                 | 97    | 70800        |
| 97                 | 98    | 72265        |
| 98                 | 99    | 73745        |
| 99                 | 100   | 75240        |
| 100                | 101   | 76750        |
| 101                | 102   | 78275        |
| 102                | 103   | 79815        |
| 103                | 104   | 81370        |
| 104                | 105   | 82940        |
| 105                | 106   | 84525        |
| 106                | 107   | 86125        |
| 107                | 108   | 87740        |
| 108                | 109   | 89370        |
| 109                | 110   | 91015        |
| 110                | 111   | 92675        |

....

### Used Framework's documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
