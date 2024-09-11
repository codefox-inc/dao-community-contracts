// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {AmbassadorNft} from "src/AmbassadorNft.sol";
import {DeployContracts, DeploymentResult} from "script/DeployContracts.s.sol";
import {ERC20UpgradeableTokenV1} from "src/ERC20UpgradeableTokenV1.sol";
import {GovToken} from "src/GovToken.sol";
import {VotingPowerExchange} from "src/VotingPowerExchange.sol";
import {VotingPowerExchangeTestHelper} from "../integration/utils/VotingPowerExchangeTestHelper.t.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract VotingPwoerExchangeTest is Test {
    // instances
    GovToken public govToken;
    ERC20UpgradeableTokenV1 public utilityToken;
    VotingPowerExchange public votingPowerExchange;
    DeployContracts public dc;
    VotingPowerExchangeTestHelper public helper;

    DeploymentResult result;

    // admin roles
    address admin;
    address pauser;
    address minter;
    address burner;
    address manager;
    address exchanger;

    // users for testing
    address public user = makeAddr("user");
    address public user2 = makeAddr("user2");

    // user for testing exchange
    address public participant = makeAddr("levelUpper2");
    address public participant2;

    // private key
    uint256 public default_anvil_key2 = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    // deploy scripts
    function setUp() public {
        dc = new DeployContracts();
        result = dc.run();

        utilityToken = ERC20UpgradeableTokenV1(result.utilityToken);
        govToken = GovToken(result.govToken);
        votingPowerExchange = VotingPowerExchange(result.exchange);
        admin = result.admin;
        pauser = result.pauser;
        minter = result.minter;
        burner = result.burner;
        manager = result.manager;
        exchanger = result.exchanger;
        participant2 = vm.addr(dc.DEFAULT_ANVIL_KEY2());

        vm.startPrank(minter);
        govToken.mint(user, 15 * 1e17);
        utilityToken.mint(user, 1_000 * 1e18);
        utilityToken.mint(participant, 100_000 * 1e18);
        utilityToken.mint(participant2, 10_000 * 1e18);
        vm.stopPrank();

        // set up the roles for exchange contract

        helper = new VotingPowerExchangeTestHelper();

        // other setup
        vm.label(participant, "participant");
        vm.label(participant2, "participant2");
        vm.label(user, "user");
        vm.label(user2, "user2");
    }

    ///////////////////////////
    ///// Other functions /////
    ///////////////////////////
    /// The `setVotingPowerCap` function
    function testSetVotingPowerCap(uint256 cap) public {
        vm.assume(cap > votingPowerExchange.getVotingPowerCap());
        vm.prank(manager);
        vm.expectEmit(true, true, true, true);
        emit VotingPowerExchange.VotingPowerCapSet(cap);
        votingPowerExchange.setVotingPowerCap(cap);
        assertEq(votingPowerExchange.getVotingPowerCap(), cap);
    }

    function testSetVotingPowerCap_revertWhenLowerThanExisting(uint256 cap) public {
        vm.assume(cap <= votingPowerExchange.getVotingPowerCap());
        vm.prank(manager);
        vm.expectRevert(VotingPowerExchange.VotingPowerExchange__LevelIsLowerThanExisting.selector);
        votingPowerExchange.setVotingPowerCap(cap);
    }

    function testSetVotingPowerCap_revertWhenNonManagerCalled(address nonManager) public {
        vm.assume(nonManager != manager);
        vm.prank(nonManager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, nonManager, votingPowerExchange.MANAGER_ROLE()
            )
        );
        vm.prank(nonManager);
        votingPowerExchange.setVotingPowerCap(100e18);
    }

    ///////////////////////////////////////////////////////////
    /// Test the `calculateIncrementedVotingPower` function ///
    ///////////////////////////////////////////////////////////
    function testCalculateIncrementedVotingPower(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 92675e18);
        uint256 currentBurnedAmount = uint256(0);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0);
        assertTrue(incrementedVotingPower <= 110e18);
    }

    function testCalculateIncrementedVotingPower_0_to_10(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 925e18);
        uint256 currentBurnedAmount = uint256(0);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0);
        assertTrue(incrementedVotingPower <= 10e18);
    }

    function testCalculateIncrementedVotingPower_10_to_20(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 2425e18);
        uint256 currentBurnedAmount = uint256(925e18);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0e18);
        assertTrue(incrementedVotingPower <= 10e18);
    }

    function testCalculateIncrementedVotingPower_20_to_30(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 3925e18);
        uint256 currentBurnedAmount = uint256(3350e18);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0e18);
        assertTrue(incrementedVotingPower <= 10e18);
    }

    function testCalculateIncrementedVotingPower_30_to_40(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 5425e18);
        uint256 currentBurnedAmount = uint256(7275e18);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0e18);
        assertTrue(incrementedVotingPower <= 10e18);
    }

    function testCalculateIncrementedVotingPower_40_to_50(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 6925e18);
        uint256 currentBurnedAmount = uint256(12700e18);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0e18);
        assertTrue(incrementedVotingPower <= 10e18);
    }

    function testCalculateIncrementedVotingPower_50_to_60(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 8425e18);
        uint256 currentBurnedAmount = uint256(20815e18);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0e18);
        assertTrue(incrementedVotingPower <= 10e18);
    }

    function testCalculateIncrementedVotingPower_60_to_70(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 9925e18);
        uint256 currentBurnedAmount = uint256(31840e18);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0e18);
        assertTrue(incrementedVotingPower <= 10e18);
    }

    function testCalculateIncrementedVotingPower_70_to_80(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 11425e18);
        uint256 currentBurnedAmount = uint256(45765e18);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0e18);
        assertTrue(incrementedVotingPower <= 10e18);
    }

    function testCalculateIncrementedVotingPower_80_to_90(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 12925e18);
        uint256 currentBurnedAmount = uint256(62325e18);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0e18);
        assertTrue(incrementedVotingPower <= 10e18);
    }

    function testCalculateIncrementedVotingPower_90_to_100(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 0, 14425e18);
        uint256 currentBurnedAmount = uint256(92675e18);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 0e18);
        assertTrue(incrementedVotingPower <= 10e18);
    }

    function testCalculateIncrementedVotingPower_10_to_110(uint256 incrementedAmount) public view {
        // limit the incrementedAmount to a reasonable range
        incrementedAmount = bound(incrementedAmount, 925e18, 92675e18);
        uint256 currentBurnedAmount = uint256(0);

        uint256 incrementedVotingPower =
            votingPowerExchange.calculateIncrementedVotingPower(incrementedAmount, currentBurnedAmount);
        assertTrue(incrementedVotingPower >= 10e18);
        assertTrue(incrementedVotingPower <= 110e18);
    }

    ///////////////////////////////////////////////////////////////
    /// Test the `calculateVotingPowerFromBurnedAmount` function //
    ///////////////////////////////////////////////////////////////
    function testFuzzCalculateVotingPowerFromBurnedAmount(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 0, 92675e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 0);
        assertTrue(votingPower <= 110e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_76750_92675(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 76750e18, 92675e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 100e18);
        assertTrue(votingPower <= 110e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_62325_76750(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 62325e18, 76750e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 90e18);
        assertTrue(votingPower <= 100e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_49400_62325(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 49400e18, 62325e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 80e18);
        assertTrue(votingPower <= 90e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_37975_49400(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 37975e18, 49400e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 70e18);
        assertTrue(votingPower <= 80e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_28050_37975(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 28050e18, 37975e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 60e18);
        assertTrue(votingPower <= 70e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_19625_28050(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 19625e18, 28050e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 50e18);
        assertTrue(votingPower <= 60e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_12700_19625(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 12700e18, 19625e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 40e18);
        assertTrue(votingPower <= 50e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_7275_12700(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 7275e18, 12700e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 30e18);
        assertTrue(votingPower <= 40e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_3350_7275(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 3350e18, 7275e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 20e18);
        assertTrue(votingPower <= 30e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_925_3350(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 925e18, 3350e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 10e18);
        assertTrue(votingPower <= 20e18);
    }

    function testFuzzCalculateVotingPowerFromBurnedAmount_0_925(uint256 burnedAmount) public view {
        // limit the burnedAmount to a reasonable range
        burnedAmount = bound(burnedAmount, 0, 925e18);

        uint256 votingPower = votingPowerExchange.calculateVotingPowerFromBurnedAmount(burnedAmount);
        uint256 expectedVotingPower = calculateExpectedVotingPower(burnedAmount);

        assertEq(votingPower, expectedVotingPower);
        assertTrue(votingPower >= 0);
        assertTrue(votingPower <= 10e18);
    }

    //////////////////////////////////////////////////////////////
    /// Test the `calculateIncrementedBurningAmount` function ////
    //////////////////////////////////////////////////////////////
    function testFuzzCalculateIncrementedBurningAmount_0_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = uint256(0);
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 110e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 92675e18);
    }

    function testFuzzCalculateIncrementedBurningAmount_10_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = 10e18;
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 100e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 91910e18);
    }

    function testFuzzCalculateIncrementedBurningAmount_20_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = 20e18;
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 90e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 89325e18);
    }

    function testFuzzCalculateIncrementedBurningAmount_30_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = 30e18;
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 80e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 85400e18);
    }

    function testFuzzCalculateIncrementedBurningAmount_40_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = 40e18;
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 70e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 85400e18);
    }

    function testFuzzCalculateIncrementedBurningAmount_50_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = 50e18;
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 60e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 73050e18);
    }

    function testFuzzCalculateIncrementedBurningAmount_60_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = 60e18;
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 50e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 64625e18);
    }

    function testFuzzCalculateIncrementedBurningAmount_70_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = 70e18;
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 40e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 54700e18);
    }

    function testFuzzCalculateIncrementedBurningAmount_80_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = 80e18;
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 30e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 43275e18);
    }

    function testFuzzCalculateIncrementedBurningAmount_90_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = 90e18;
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 20e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 30350e18);
    }

    function testFuzzCalculateIncrementedBurningAmount_100_to_110(uint256 incrementedVotingPower) public view {
        // limit the currentBurnedAmount to a reasonable range
        uint256 currentVotingPower = 100e18;
        // limit the incrementedAmount to a reasonable range
        incrementedVotingPower = bound(incrementedVotingPower, 0, 10e18);

        uint256 incrementedBurningAmount =
            votingPowerExchange.calculateIncrementedBurningAmount(incrementedVotingPower, currentVotingPower);

        assertTrue(incrementedBurningAmount >= 0);
        assertTrue(incrementedBurningAmount <= 15925e18);
    }

    /////////////////////////////////////////////////////////////////
    /// Test the `calculateBurningAmountFromVotingPower` function ///
    /////////////////////////////////////////////////////////////////
    function testFuzzCalculateBurningAmountFromVotingPower_0_110(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 0, 110e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 0);
        assertTrue(burningAmount <= 92675e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_100_110(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 100e18, 110e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 76750e18);
        assertTrue(burningAmount <= 92675e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_90_100(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 90e18, 100e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 62325e18);
        assertTrue(burningAmount <= 76750e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_80_90(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 80e18, 90e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 49400e18);
        assertTrue(burningAmount <= 62325e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_70_80(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 70e18, 80e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 37975e18);
        assertTrue(burningAmount <= 49400e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_60_70(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 60e18, 70e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 28050e18);
        assertTrue(burningAmount <= 37975e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_50_60(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 50e18, 60e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 19625e18);
        assertTrue(burningAmount <= 28050e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_40_50(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 40e18, 50e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 12700e18);
        assertTrue(burningAmount <= 19625e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_30_40(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 30e18, 40e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 7275e18);
        assertTrue(burningAmount <= 12700e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_20_30(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 20e18, 30e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 3350e18);
        assertTrue(burningAmount <= 7275e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_10_20(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 10e18, 20e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 925e18);
        assertTrue(burningAmount <= 3350e18);
    }

    function testFuzzCalculateBurningAmountFromVotingPower_0_10(uint256 votingPowerAmount) public view {
        // limit the votingPowerAmount to a reasonable range
        votingPowerAmount = bound(votingPowerAmount, 0, 10e18);

        uint256 burningAmount = votingPowerExchange.calculateBurningAmountFromVotingPower(votingPowerAmount);
        uint256 expectedBurningAmount = calculateExpectedBurningAmount(votingPowerAmount);

        assertEq(burningAmount, expectedBurningAmount);
        assertTrue(burningAmount >= 0);
        assertTrue(burningAmount <= 925e18);
    }

    function calculateExpectedBurningAmount(uint256 votingPowerAmount) internal pure returns (uint256) {
        uint256 term = 15 * (votingPowerAmount * votingPowerAmount) / 1e18 + 35 * votingPowerAmount;
        return term / 2;
    }

    function calculateExpectedVotingPower(uint256 burnedAmount) internal pure returns (uint256) {
        uint256 innerValue = (30625 * 1e16 + 30 * burnedAmount);
        uint256 sqrtPart = 2 * Math.sqrt(innerValue) * 1e9;
        return (uint256(sqrtPart) - 5 * 1e18) / 30 - 1e18;
    }
}
