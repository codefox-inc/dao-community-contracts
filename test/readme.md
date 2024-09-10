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

## Fuzz Tests

Fuzz tests have not been started yet.

## Coverage
