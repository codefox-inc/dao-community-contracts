# Test Cases

We conducted the following categories of tests to ensure the correctness and robustness of the smart contracts we have developed:

1. Unit Tests
2. Integration Tests
3. Fuzz Tests

We will list up all the test cases we have set up for these categories here.

## Unit Tests

### AmbassadorNft.t.sol

This is the NFT contract for the ambassador program.

- setUp
- testTokenRoles
- testMintingTokensSuccessfully
- testMintingTokenWillFailByNonMinter
- testMintingTokenWillSucceedByNewMinter
- testBurningTokenSuccessfully
- testBurningTokenWillFailByNonBurner
- testBurningTokenWillSucceedByNewBurner
- testSetURI
- testSetURIByNonUriSetter
- testBalanceOfWorks
- testBalanceOfBatchWorks
- testTransferWillWork

### ERC20UpgradeableTokenV1.t.sol

This is the utility token contract.

- setUp
- testSucceedingToBurnTokens
- testFailingToBurnTokens
- testShowingBasicTokenInfo
- testRolesAreSetCorrectly
- testPausingAndUnpausing
- testGrantRoles
- testGrantingAndRevokingRoles
- testApprovingSpending
- testApprovingAndTransferFrom
- testApprovingAllAndTransferFromAll
- testApprovingAllAndTransferFromHalf
- testSendingTokens
- testUpgradeabilityOfToken

### VotingPowerExchange.t.sol

- setUp
- testSpecialCasesForCalculateVotingPowerFromBurnedAmount
- testSomeMoreSpecialCasesForCalculateVotingPowerFromBurnedAmount
- testCalculateVotingPowerFromBurnedAmount
- testCalculateVotingPowerFromBurnedAmountRareCases
- testCalculationOfVotingPowerMintingWhenMintedSeparately
- testCalculationOfVotingPowerMintingWhenMintedSeparately2
- testCalculateIncrementedVotingPower
- testCalculateBurningAmountFromVotingPower
- testCalculateIncrementedBurningAmount

### GovToken.t.sol

This is the token contract for the governance system.

- setUp
- testTokensAreNotTransferrable
- testTokenMintingCanBeDoneByMinter
- testTokenMintingCannotBeDoneByNonMinter
- testTokenMintingCanBeDoneByNewMinter
- testBurningCanBeDoneByBurner
- testBurningCannotBeDoneByNonBurner
- testBurningCanBeDoneByNewBurner
- testVotingPowerExchangeCanCallSetBurnedAmountOfUtilToken
- testNonRoleCannotCallSetBurnedAmountOfUtilToken
- testSetBurnedAmountOfUtilTokenEvent
- testTheRolesOfTheGovToken
- testTheTokenInfos

## Integration Tests

### VotingPowerExchange.t.sol

Some basic tests

- setUp
- testReturnedSetupValues
- testTokensAccessRoles
- testVotingPowerExchangeRoles
- testUtilityTokenBasicInfo
- testGovTokenBasicInfo
- testGovTokenNotBeingTransferrable
- testUtilityTokenCanBeTransferred
- testTokensBalanceOf
- testTokensBurning
- testUtilityTokensPausability

Core tests for VotingPowerExchange

- testVotingPowerExchangePausability
- testVotingPowerExchangeCanBeExchanged
- testVotingPowerExchangeCannotBeExchangedByNonExchanger
- testVotingPowerExchangeCannotBeExchangedByNonExchanger
- testVotingPowerExchangeCannotBeExchangedByNonExchanger
- testVotingPowerExchangeCannotBeExchangedByNonExchanger

Preparation internal functions

- createDigest
- checkExchangeResult

## Fuzz Tests

exchange function

- testExchangeWithDifferentSender
- testExchangeWithDifferentAmount
- testExchangeWithDifferentNonce
- testExchangeWithDifferentExpiration
- testExchangeWithDifferentSignature
- testExchangeWithDifferentVotingPowerCap

other functions

- testSetVotingPowerCap
- testCalculateIncrementedVotingPower
- testCalculateVotingPowerFromBurnedAmount
- testCalculateBurningAmountFromVotingPower
- testCalculateIncrementedBurningAmount

## Coverage

| File                        | % Lines         | % Statements    | % Branches      | % Funcs         |
| --------------------------- | --------------- | --------------- | --------------- | --------------- |
| src/VotingPowerExchange.sol | 100.00% (53/53) | 100.00% (80/80) | 100.00% (10/10) | 100.00% (12/12) |

# Reference

## voting power calculation table

These are the values we used in the fuzz tests for voint power <->

```
x = (2 \* sqrt(306.25 + 30y) - 5) / 30 - 1
y = (15*x^2+35*x)/2

x = mintedToken
y = burnedToken
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
