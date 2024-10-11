// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {AmbassadorNft} from "src/AmbassadorNft.sol";
import {DeployContracts, DeploymentResult} from "script/DeployContracts.s.sol";
import {ERC20UpgradeableTokenV1} from "src/ERC20UpgradeableTokenV1.sol";
import {GovToken} from "src/GovToken.sol";
import {VotingPowerExchange} from "src/VotingPowerExchange.sol";
import {VotingPowerExchangeTestHelper} from "./utils/VotingPowerExchangeTestHelper.t.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract VotingPowerExchangeTest is Test {
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
        utilityToken.mint(exchanger, 10_000 * 1e18);
        vm.stopPrank();

        vm.prank(exchanger);
        utilityToken.approve(address(votingPowerExchange), 10_000 * 1e18);

        // set up the roles for exchange contract

        helper = new VotingPowerExchangeTestHelper();

        // set the voting power cap to 99e18
        vm.prank(manager);
        votingPowerExchange.setVotingPowerCap(99e18);

        // other setup
        vm.label(participant, "participant");
        vm.label(participant2, "participant2");
        vm.label(user, "user");
        vm.label(user2, "user2");
        vm.label(address(votingPowerExchange), "votingPowerExchange");
        vm.label(address(utilityToken), "utilityToken");
        vm.label(address(govToken), "govToken");
    }

    ////////////////////////////
    ///// Some basic tests /////
    ////////////////////////////
    function testReturnedSetupValues() public view {
        assertEq(address(utilityToken), address(result.utilityToken), "utilityToken address is not the same");
        assertEq(address(govToken), address(result.govToken), "govToken address is not the same");
        assertEq(address(votingPowerExchange), address(result.exchange), "votingPowerExchange address is not the same");
        assertEq(admin, result.admin, "admin address is not the same");
        assertEq(pauser, result.pauser, "pauser address is not the same");
        assertEq(minter, result.minter, "minter address is not the same");
        assertEq(burner, result.burner, "burner address is not the same");
        assertEq(manager, result.manager, "manager address is not the same");
        assertEq(exchanger, result.exchanger, "exchanger address is not the same");

        assertTrue(address(utilityToken) != address(0), "utilityToken address is zero");
        assertTrue(address(govToken) != address(0), "govToken address is zero");
        assertTrue(address(votingPowerExchange) != address(0), "votingPowerExchange address is zero");
        assertTrue(admin != address(0), "admin address is zero");
        assertTrue(pauser != address(0), "pauser address is zero");
        assertTrue(minter != address(0), "minter address is zero");
        assertTrue(burner != address(0), "burner address is zero");
        assertTrue(manager != address(0), "manager address is zero");
        assertTrue(exchanger != address(0), "exchanger address is zero");
    }

    function testTokensAccessRoles() public view {
        // test gov token
        assertEq(govToken.hasRole(govToken.DEFAULT_ADMIN_ROLE(), admin), true);
        assertEq(govToken.hasRole(govToken.MINTER_ROLE(), minter), true);
        assertEq(govToken.hasRole(govToken.BURNER_ROLE(), burner), true);

        // test utility token
        assertEq(utilityToken.hasRole(utilityToken.DEFAULT_ADMIN_ROLE(), admin), true);
        assertEq(utilityToken.hasRole(utilityToken.PAUSER_ROLE(), pauser), true);
        assertEq(utilityToken.hasRole(utilityToken.MINTER_ROLE(), minter), true);
        assertEq(utilityToken.hasRole(utilityToken.BURNER_ROLE(), burner), true);
    }

    function testVotingPowerExchangesRoles() public view {
        // test voting power exchange
        assertEq(votingPowerExchange.hasRole(votingPowerExchange.DEFAULT_ADMIN_ROLE(), admin), true);
        assertEq(votingPowerExchange.hasRole(votingPowerExchange.MANAGER_ROLE(), manager), true);
        assertEq(votingPowerExchange.hasRole(votingPowerExchange.EXCHANGER_ROLE(), exchanger), true);

        // special roles when deploying voting power exchange
        assertEq(govToken.hasRole(govToken.MINTER_ROLE(), address(votingPowerExchange)), true);
        assertEq(utilityToken.hasRole(utilityToken.BURNER_ROLE(), address(votingPowerExchange)), true);
    }

    function testUtilityTokenBasicInfo() public view {
        assertEq(utilityToken.name(), "AMA coin");
        assertEq(utilityToken.symbol(), "AMA");
        assertEq(utilityToken.decimals(), 18);
        assertEq(utilityToken.totalSupply(), 121_000 * 1e18);
    }

    function testGovTokenBasicInfo() public view {
        assertEq(govToken.name(), "Governance Token");
        assertEq(govToken.symbol(), "GOV");
        assertEq(govToken.decimals(), 18);
        assertEq(govToken.totalSupply(), 15 * 1e17);
    }

    function testGovTokenNotBeingTransferrable() public {
        vm.prank(minter);
        govToken.mint(address(1), 1);
        assertEq(govToken.balanceOf(address(1)), 1);

        vm.expectRevert(GovToken.TokenTransferNotAllowed.selector);
        govToken.transfer(address(2), 1);
        assertEq(govToken.balanceOf(address(2)), 0);
    }

    function testUtilityTokenCanBeTransferred() public {
        vm.startPrank(minter);
        utilityToken.mint(address(1), 10);
        assertEq(utilityToken.balanceOf(address(1)), 10);
        vm.stopPrank();

        vm.prank(address(1));
        utilityToken.transfer(address(2), 3);
        assertEq(utilityToken.balanceOf(address(2)), 3);
        assertEq(utilityToken.balanceOf(address(1)), 7);
    }

    function testTokensBalanceOf() public view {
        assertEq(utilityToken.balanceOf(user), 1000 * 1e18);
        assertEq(govToken.balanceOf(user), 15 * 1e17);
    }

    function testTokensBurning() public {
        // utility token
        assertEq(utilityToken.balanceOf(participant2), 10_000 * 1e18);
        vm.startPrank(burner);
        utilityToken.burnByBurner(participant2, 1_000 * 1e18);
        assertEq(utilityToken.balanceOf(participant2), 9_000 * 1e18);
        vm.stopPrank();

        // gov token
        assertEq(govToken.balanceOf(user), 15 * 1e17);
        vm.startPrank(burner);
        govToken.burnByBurner(user, 1 * 1e17);
        assertEq(govToken.balanceOf(user), 14 * 1e17);
        vm.stopPrank();
    }

    function testUtilityTokensPausability() public {
        vm.prank(pauser);
        utilityToken.pause();
        assertEq(utilityToken.paused(), true);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(user);
        utilityToken.transfer(user2, 1);

        vm.prank(pauser);
        utilityToken.unpause();
        assertEq(utilityToken.paused(), false);
        vm.prank(user);
        utilityToken.transfer(user2, 1);

        assertEq(utilityToken.balanceOf(user2), 1);
    }

    //////////////////////////////////////////////
    ///// Core tests for VotingPowerExchange /////
    //////////////////////////////////////////////
    function testConstructorOfVotingPowerExchange() public {
        vm.expectRevert(VotingPowerExchange.VotingPowerExchange__DefaultAdminCannotBeZero.selector);
        new VotingPowerExchange(address(utilityToken), address(govToken), address(0), manager, exchanger);

        VotingPowerExchange vpe =
            new VotingPowerExchange(address(utilityToken), address(govToken), admin, manager, exchanger);
        assertTrue(address(vpe) != address(0));
        assertEq(vpe.getVotingPowerCap(), 49 * 1e18);
    }

    function testBasicVotingPowerExchangeInfo() public view {
        (address _utilityToken, address _govToken) = votingPowerExchange.getTokenAddresses();
        assertEq(_govToken, address(govToken));
        assertEq(_utilityToken, address(utilityToken));
    }

    function testConstantValues() public view {
        (
            bytes32 __EXCHANGE_TYPEHASH,
            uint256 _PRICISION_FIX,
            uint256 _PRICISION,
            uint256 _ALLOWED_EXCHANGING_MINIMUM_AMOUNT
        ) = votingPowerExchange.getConstants();

        assertEq(
            __EXCHANGE_TYPEHASH, keccak256("Exchange(address sender,uint256 amount,bytes32 nonce,uint256 expiration)")
        );
        assertEq(_PRICISION, 1e18);
        assertEq(_PRICISION_FIX, 1e9);
        assertEq(_ALLOWED_EXCHANGING_MINIMUM_AMOUNT, 1e18);
    }

    function testVotingPowerCap() public view {
        uint256 cap = votingPowerExchange.getVotingPowerCap();
        assertEq(cap, 99 * 1e18);
    }

    function testSettingVotingPowerCap() public {
        uint256 cap = votingPowerExchange.getVotingPowerCap();
        assertEq(cap, 99 * 1e18);

        uint256 newCap = 109 * 1e18;
        vm.startPrank(manager);
        vm.expectEmit();
        emit VotingPowerExchange.VotingPowerCapSet(newCap);
        votingPowerExchange.setVotingPowerCap(newCap);
        assertEq(votingPowerExchange.getVotingPowerCap(), newCap);
        vm.stopPrank();
    }

    function testSettingVotingPowerCapFails() public {
        vm.prank(user);
        vm.expectRevert();
        votingPowerExchange.setVotingPowerCap(1000 * 1e18);
    }

    function testSettingVotingPowerCapFailsCase2() public {
        vm.prank(manager);
        vm.expectRevert(VotingPowerExchange.VotingPowerExchange__LevelIsLowerThanExisting.selector);
        votingPowerExchange.setVotingPowerCap(99 * 1e18);

        vm.prank(manager);
        vm.expectRevert(VotingPowerExchange.VotingPowerExchange__LevelIsLowerThanExisting.selector);
        votingPowerExchange.setVotingPowerCap(90 * 1e18);
    }

    // this test only run the test for the calculation of increased voting power function
    // 75240 -> 99 voting power
    // 3350 -> 20 voting power
    // 765 -> 10 voting power
    // 190 -> 4 voting power
    // 4255 -> 22~23 voting power
    // 10000 -> 35~36 voting power
    function testCalculationOfIncreasedVotingPowerWhenCurrentIsZero() public view {
        // when you exchange 75_240 utility token, you will get 99 voting power
        uint256 increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(75240 * 1e18, 0);
        assertEq(increasedVotingPower, 99 * 1e18);
        // when you exchange 3350 utility token, you will get 20 voting power
        increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(3350 * 1e18, 0);
        assertEq(increasedVotingPower, 20 * 1e18);
        // when you exchange 765 utility token, you will get 9 voting power
        increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(765 * 1e18, 0);
        assertEq(increasedVotingPower, 9 * 1e18);
        // when you exchange 4255 utility token, you will get 22~23 voting power
        increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(4255 * 1e18, 0);
        assertTrue(increasedVotingPower > 225 * 1e17);
        assertTrue(increasedVotingPower < 23 * 1e18);
        // when you exchange 10000 utility token, you will get 35~36 voting power
        increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(10000 * 1e18, 0);
        assertTrue(increasedVotingPower > 35 * 1e18);
        assertTrue(increasedVotingPower < 36 * 1e18);
    }

    // this test only run the test for the calculation of increased voting power function
    // increasedVotingPower | currentVotingPower
    // 6175 | 1100 -> 138.29 voting power
    // 5100 | 25 -> 24 voting power
    // 300 | 9800 -> less than 1 voting power
    // 250 | 10_100 -> 1 voting power for getting to level 36 with previous test
    // 75240 | 25 -> 98~99 voting power
    // 94350 | 65 -> 109~110 voting power
    // 500 | 25 -> 6~7 voting power
    function testCalculationOfIncreasedVotingPowerWhenCurrentIsNotZero() public view {
        // when you exchange 6175 utility token and burned token is currently 1100 * 1e18, you will get 19 voting power
        uint256 increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(6175 * 1e18, 1100 * 1e18);
        assertEq(increasedVotingPower, 19 * 1e18);
        // assertTrue(increasedVotingPower < 1383 * 1e17);
        // assertTrue(increasedVotingPower > 1382 * 1e17);
        // when you exchange 5100 utility token with current burned token as 25 * 1e18, you will get 24 voting power
        increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(5100 * 1e18, 25 * 1e18);
        assertEq(increasedVotingPower, 24 * 1e18);
        // when you exchange 300 utility token with current burned tokken as 9800 * 1e18, you will get less than 1 voting power
        uint256 increasedVotingPower2 = votingPowerExchange.calculateIncrementedVotingPower(300 * 1e18, 9800 * 1e18);
        assertTrue(increasedVotingPower2 < 1 * 1e18);
        assertTrue(increasedVotingPower2 > 0);
        // when you exchange 250 utility token with current burned token as 10_100 * 1e18, you will get a full 1 voting power to become level 36
        increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(250 * 1e18, 10_100 * 1e18);
        assertTrue(increasedVotingPower < 1 * 1e18);
        assertTrue(increasedVotingPower > 0);
        assertEq(increasedVotingPower + increasedVotingPower2, 1 * 1e18);
        // when you exchange 75240 utility token with current burned token as 25, you will get 98~99 voting power
        increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(75240 * 1e18, 25 * 1e18);
        assertTrue(increasedVotingPower < 99 * 1e18);
        assertTrue(increasedVotingPower > 98 * 1e18);
        // when you exchange 94350 utility token with current burned token as 65 * 1e18, you will get over 109~110 voting power
        increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(94350 * 1e18, 65 * 1e18);
        assertTrue(increasedVotingPower < 110 * 1e18);
        assertTrue(increasedVotingPower > 109 * 1e18);
        // when you exchange 500 utility token with current burned token as 25 * 1e18, you will get 6~7 voting power
        increasedVotingPower = votingPowerExchange.calculateIncrementedVotingPower(500 * 1e18, 25 * 1e18);
        assertTrue(increasedVotingPower < 7 * 1e18);
        assertTrue(increasedVotingPower > 6 * 1e18);
    }

    // this test only run the test for the calculation of required amount to be burned function
    // 100 voting power | 0 -> 76750 utility token
    // 10 voting power | 0 -> 925 utility token
    // 3 voting power | 0 -> 120 utility token
    // 1 voting power | 0 -> 25 utility token
    // 90 voting power | 0 -> 62325 utility token
    // 50 voting power | 0 -> 19625 utility token
    function testCalculateIncrementedBurningAmountWhenCurrentIsZero() public view {
        // when you exchange 100 voting power, you need to burn 76750 utility token
        uint256 requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(100 * 1e18, 0);
        assertEq(requiredAmount, 76750 * 1e18);
        // when you exchange 10 voting power, you need to burn 925 utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(10 * 1e18, 0);
        assertEq(requiredAmount, 925 * 1e18);
        // when you exchange 3 voting power, you need to burn 1_000 utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(3 * 1e18, 0);
        assertEq(requiredAmount, 120 * 1e18);
        // when you exchange 1 voting power, you need to burn 100 utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(1 * 1e18, 0);
        assertEq(requiredAmount, 25 * 1e18);

        // when you exchange 90 voting power, you need to burn 810_000 utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(90 * 1e18, 0);
        assertEq(requiredAmount, 62325 * 1e18);
        // when you exchange 50 voting power, you need to burn 19625 utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(50 * 1e18, 0);
        assertEq(requiredAmount, 19_625 * 1e18);
    }

    // this test only run the test for the calculation of required amount to be burned function
    // 7 voting power | 1 * 1e18 -> 595 utility token
    // 10 voting power | 10 * 1e18 -> 2425 utility token
    // 5 voting power | 25 * 1e18 -> 2150 utility token
    // 20 voting power | 3 * 1e18 -> 4250 utility token
    // 0.5 voting power | 39 * 1e18 -> 210~610 utility token
    // 0.6 voting power | 39 * 1e18 -> 210~610 utility token
    // 1 voting power | 39 * 1e18 -> 610 utility token
    function testCalculateIncrementedBurningAmountWhenCurrentIsNotZero() public view {
        // when you exchange 7 voting power with current voting power as 1 * 1e18, you need to burn 465 utility token
        uint256 requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(7 * 1e18, 1 * 1e18);
        assertEq(requiredAmount, 595 * 1e18);
        // when you exchange 10 voting power with current voting power as 10 * 1e18, you need to burn 2525 utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(10 * 1e18, 10 * 1e18);
        assertEq(requiredAmount, 2425 * 1e18);
        // when you exchange 5 voting power with current voting power as 25 * 1e18, you need to burn 2150 utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(5 * 1e18, 25 * 1e18);
        assertEq(requiredAmount, 2150 * 1e18);
        // when you exchange 20 voting power with current voting power as 3 * 1e18, you need to burn 4250 utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(20 * 1e18, 3 * 1e18);
        assertEq(requiredAmount, 4250 * 1e18);

        // when you exchange 0.5 voting power with current voting power as 39 * 1e18, you need to burn ? utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(0.5 * 1e18, 39 * 1e18);
        // assertApproxEqRel(requiredAmount, 301 * 1e18, 0.01);
        assertTrue(requiredAmount > 210 * 1e18);
        assertTrue(requiredAmount < 610 * 1e18);

        // when you exchange 0.6 voting power with current voting power as 39 * 1e18, you need to burn ? utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(0.6 * 1e18, 39 * 1e18);
        assertTrue(requiredAmount > 210 * 1e18);
        assertTrue(requiredAmount < 610 * 1e18);

        // when you exchange 0.6 voting power with current voting power as 39 * 1e18, you need to burn ? utility token
        requiredAmount = votingPowerExchange.calculateIncrementedBurningAmount(1 * 1e18, 39 * 1e18);
        assertEq(requiredAmount, 610 * 1e18);
    }

    //////////////////////////////
    /////// Exchange tests ///////
    //////////////////////////////
    ////// test success cases //////
    function testExchangeMediumAmountSuccessCase() public {
        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        console.log(block.chainid);
        console.log("Signer address:", vm.addr(dc.DEFAULT_ANVIL_KEY2()));
        console.log("participant2 address:", participant2);

        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 1_100 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        // exchanger is exchanging the token on behalf of participant2
        vm.startPrank(exchanger);
        // when you exchange 1_100 utility token, you will get 11 voting power
        vm.expectEmit();
        emit VotingPowerExchange.VotingPowerReceived(participant2, 1_100 * 1e18, 11 * 1e18);
        votingPowerExchange.exchange(participant2, 1_100 * 1e18, nonce, expirationTime, signature);
        vm.stopPrank();

        // Check the result of the exchange:
        // Participant2 receives 11 governance tokens, has 8_900 utility tokens remaining,
        // has burned 1_100 utility tokens, and uses a specific nonce, which is used, so the authorization state should be true
        // Participant has burned 0 utility token
        checkExchangeResult(participant2, 11 * 1e18, 8_900 * 1e18, 1_100 * 1e18, address(participant), 0, nonce, true);
    }

    function testExchangeSmallAmountSuccessCase() public {
        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 1 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        vm.startPrank(exchanger);
        // when you exchange 1_100 utility token, you will get 11 voting power
        vm.expectEmit();
        emit VotingPowerExchange.VotingPowerReceived(participant2, 1 * 1e18, 55808054666666666);
        votingPowerExchange.exchange(participant2, 1 * 1e18, nonce, expirationTime, signature);
        vm.stopPrank();

        // Participant2 receives 5.5808054666666666e16 voting power, has 10_000 * 1e18 - 1 * 1e18 utility tokens remaining,
        // has burned 1 * 1e18 utility tokens, and uses a specific nonce, which is used, so the authorization state should be true
        // Participant has burned 0 utility token
        checkExchangeResult(
            participant2, 55808054666666666, 10_000 * 1e18 - 1 * 1e18, 1 * 1e18, address(participant), 0, nonce, true
        );
    }

    function testExchangeLargeAmountSuccessCase() public {
        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 9800 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        vm.startPrank(exchanger);
        // when you exchange 1_100 utility token, you will get 11 voting power
        vm.expectEmit();
        emit VotingPowerExchange.VotingPowerReceived(participant2, 9800 * 1e18, 35 * 1e18);
        votingPowerExchange.exchange(participant2, 9800 * 1e18, nonce, expirationTime, signature);
        vm.stopPrank();

        // Check the result of the humongous token exchange:
        // Participant2 receives 35 governance tokens, has 200 utility tokens remaining,
        // has burned 9800 utility tokens, and uses a specific nonce, which is used, so the authorization state should be true
        // Participant has burned 0 utility token
        checkExchangeResult(
            participant2, 35 * 1e18, 10_000 * 1e18 - 9_800 * 1e18, 9_800 * 1e18, address(participant), 0, nonce, true
        );
    }

    function testExchangeReachingVotingPowerCapSuccessCase() public {
        vm.prank(minter);
        // exchanger has already got 10_000 utility token
        utilityToken.mint(exchanger, 65_300 * 1e18);
        // approve
        vm.startPrank(exchanger);
        utilityToken.approve(address(votingPowerExchange), 75_300 * 1e18);

        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 75_240 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );

        // when you exchange 75_240 utility token, you will get 99 voting power
        vm.expectEmit();
        emit VotingPowerExchange.VotingPowerReceived(participant2, 75_240 * 1e18, 99 * 1e18);
        votingPowerExchange.exchange(participant2, 75_240 * 1e18, nonce, expirationTime, signature);
        vm.stopPrank();

        // Check the result of the humongous token exchange:
        // Participant2 receives 99 governance tokens, has 60 utility tokens remaining,
        // has burned 75240 utility tokens, and uses a specific nonce, which is used, so the authorization state should be true
        // Participant has burned 0 utility token
        checkExchangeResult(participant2, 99 * 1e18, 60 * 1e18, 75_240 * 1e18, participant, 0, nonce, true);
    }

    function testExchangeTwiceToGetToVotingPowerCapSuccessCase() public {
        vm.prank(minter);
        // exchanger has already got 10_000 utility token
        utilityToken.mint(exchanger, 75_240 * 1e18);
        vm.prank(exchanger);
        utilityToken.approve(address(votingPowerExchange), 75_240 * 1e18);

        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 2_200 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        // exchanger is exchanging the token on behalf of participant2
        vm.startPrank(exchanger);
        // when you exchange 2200 utility token, you will get 16 voting power
        vm.expectEmit();
        emit VotingPowerExchange.VotingPowerReceived(participant2, 2_200 * 1e18, 16 * 1e18);
        votingPowerExchange.exchange(participant2, 2_200 * 1e18, nonce, expirationTime, signature);
        vm.stopPrank();
        // check result for once
        checkExchangeResult(
            participant2, 16 * 1e18, 85_240 * 1e18 - 2_200 * 1e18, 2_200 * 1e18, participant, 0, nonce, true
        );

        nonce = keccak256("1");
        // when you exchange 73_040 utility token, you will get 98 voting power
        (bytes memory signature2,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 73_040 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        vm.startPrank(exchanger);
        vm.expectEmit();
        emit VotingPowerExchange.VotingPowerReceived(participant2, 73_040 * 1e18, 83 * 1e18);
        votingPowerExchange.exchange(participant2, 73_040 * 1e18, nonce, expirationTime, signature2);
        vm.stopPrank();
        checkExchangeResult(
            participant2, 99 * 1e18, 85_240 * 1e18 - 75_240 * 1e18, 75_240 * 1e18, participant, 0, nonce, true
        );
    }

    ////// test failure cases //////
    /// failure cuz of reaching cap ///
    // test description: this test means that when you exchange more than 75_240 utility token, you will only get 99 voting power token.
    // At the same time, you can only burn 75_240 utility token which matches the 99 voting power token's burning amount to get the gov token itself.
    function testExchangeTwiceToCrossVotingPowerCapFailureCase() public {
        vm.prank(minter);
        // exchanger has already got 10_000 utility token
        utilityToken.mint(exchanger, 105_240 * 1e18);
        vm.prank(exchanger);
        utilityToken.approve(address(votingPowerExchange), 105_240 * 1e18);
        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 105_240 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        vm.startPrank(exchanger);
        // when you exchange more than 75_240 utility token, you will get 16 voting power
        vm.expectEmit();
        emit VotingPowerExchange.VotingPowerReceived(participant2, 75_240 * 1e18, 99 * 1e18);
        votingPowerExchange.exchange(participant2, 105_240 * 1e18, nonce, expirationTime, signature);
        vm.stopPrank();
        // check result of this:
        // Participant2 receives 99 governance tokens, has 115_240 * 1e18 - 75_240 * 1e18 utility tokens remaining,
        // has burned 75_240 utility tokens, and uses a specific nonce, which is used, so the authorization state should be true
        // exchanger has burned 0 utility token
        checkExchangeResult(
            participant2, 99 * 1e18, 115_240 * 1e18 - 75_240 * 1e18, 75_240 * 1e18, participant, 0, nonce, true
        );
        // under this circumstance, the user cannot call the exchange function anymore and it will revert and make sure the user do not cost his utility token when calling the exchange function
        nonce = keccak256("1");
        vm.prank(exchanger);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingPowerExchange.VotingPowerExchange__VotingPowerIsHigherThanCap.selector, 99 * 1e18
            )
        );
        votingPowerExchange.exchange(participant2, 1_100 * 1e18, nonce, expirationTime, signature);
        // no state change this time, so the authorization state should be false. Others are the same as before.
        checkExchangeResult(
            participant2, 99 * 1e18, 115_240 * 1e18 - 75_240 * 1e18, 75_240 * 1e18, participant, 0, nonce, false
        );
    }

    function testExchangeFailsWhenSenderIsZeroAddress() public {
        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 1_100 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        vm.startPrank(exchanger);
        vm.expectRevert(VotingPowerExchange.VotingPowerExchange__AddressIsZero.selector);
        votingPowerExchange.exchange(address(0), 1_100 * 1e18, nonce, expirationTime, signature);
        vm.stopPrank();
    }

    function testExchangeFailCaseWhenAmountIsTooSmall() public {
        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 9e14, nonce, expirationTime, address(votingPowerExchange)
        );
        vm.startPrank(exchanger);
        vm.expectRevert(VotingPowerExchange.VotingPowerExchange__AmountIsTooSmall.selector);
        votingPowerExchange.exchange(participant2, 9e14, nonce, expirationTime, signature);
        vm.stopPrank();
    }

    function testExchangeFailCaseWhenNonceIsUsed() public {
        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 1_100 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        vm.startPrank(exchanger);
        votingPowerExchange.exchange(participant2, 1_100 * 1e18, nonce, expirationTime, signature);

        // the nonce is used so it will revert if it is used again
        (bytes memory signature2,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 100 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        vm.expectRevert(VotingPowerExchange.VotingPowerExchange__InvalidNonce.selector);
        votingPowerExchange.exchange(participant2, 100 * 1e18, nonce, expirationTime, signature2);
        vm.stopPrank();
    }

    function testExchangeFailCaseWhenSignatureExpired() public {
        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 1_100 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        vm.warp(block.timestamp + 3601);
        vm.startPrank(exchanger);
        vm.expectRevert(VotingPowerExchange.VotingPowerExchange__SignatureExpired.selector);
        votingPowerExchange.exchange(participant2, 1_100 * 1e18, nonce, expirationTime, signature);
        vm.stopPrank();
    }

    function testExchangeFailCaseWhenSenderIsNotSigner() public {
        bytes32 nonce = bytes32(0);
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 1_100 * 1e18, nonce, 3600, address(votingPowerExchange)
        );
        address invalidSigner = makeAddr("invalidSigner");
        vm.startPrank(exchanger);
        bytes32 digest = createDigest(invalidSigner, 1_100 * 1e18, nonce, 3600);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingPowerExchange.VotingPowerExchange__InvalidSignature.selector, digest, signature
            )
        );
        votingPowerExchange.exchange(invalidSigner, 1_100 * 1e18, nonce, 3600, signature);
        vm.stopPrank();
    }

    function testExchangeFailCaseWhenSignatureIsInvalid() public {
        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 1_10 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        bytes32 digest = createDigest(participant2, 1_100 * 1e18, nonce, expirationTime);
        vm.startPrank(exchanger);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingPowerExchange.VotingPowerExchange__InvalidSignature.selector, digest, signature
            )
        );
        votingPowerExchange.exchange(participant2, 1_100 * 1e18, nonce, expirationTime, signature);
        vm.stopPrank();
    }

    function testExchangeFailCaseWhenUserGotMoreThanVotingPowerCap() public {
        vm.prank(minter);
        // user has already got 10_000 utility token
        utilityToken.mint(participant2, 105_240 * 1e18);
        vm.prank(minter);
        govToken.mint(participant2, 101 * 1e18);

        bytes32 nonce = bytes32(0);
        uint256 expirationTime = 3600;
        (bytes memory signature,) = helper.generateSignatureFromPrivateKey(
            dc.DEFAULT_ANVIL_KEY2(), 105_240 * 1e18, nonce, expirationTime, address(votingPowerExchange)
        );
        vm.startPrank(exchanger);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingPowerExchange.VotingPowerExchange__VotingPowerIsHigherThanCap.selector, 101 * 1e18
            )
        );
        votingPowerExchange.exchange(participant2, 105_240 * 1e18, nonce, expirationTime, signature);
        vm.stopPrank();
    }

    //////////////////////////////////////////
    ///// Preparation internal functions /////
    //////////////////////////////////////////
    /**
     * @dev Creates a digest for EIP-712
     * @param sender The address of the sender
     * @param amount The amount of utility token to be exchanged
     * @param nonce The nonce used in the exchange transaction
     * @param expiration The expiration time of the signature
     * @return The digest of the EIP-712
     */
    function createDigest(address sender, uint256 amount, bytes32 nonce, uint256 expiration)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(helper._EXCHANGE_TYPEHASH(), sender, amount, nonce, expiration));
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("VotingPowerExchange")),
                keccak256(bytes("1")),
                block.chainid,
                address(votingPowerExchange)
            )
        );
        return MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
    }

    /**
     * @dev Checks the result of a token exchange operation
     * @param user10 The address of the user who performed the exchange
     * @param expectedGovTokenBalance The expected balance of governance tokens after the exchange
     * @param expectedUtilityTokenBalance The expected balance of utility tokens after the exchange
     * @param expectedBurnedAmount The expected amount of utility tokens burned during the exchange
     * @param user20 The address of the user who did not perform the exchange
     * @param expectedBurnedAmount2 The expected amount of utility tokens burned during the exchange
     * @param nonce The nonce used in the exchange transaction
     */
    function checkExchangeResult(
        address user10,
        uint256 expectedGovTokenBalance,
        uint256 expectedUtilityTokenBalance,
        uint256 expectedBurnedAmount,
        address user20,
        uint256 expectedBurnedAmount2,
        bytes32 nonce,
        bool expectedAuthorizationState
    ) internal view {
        assertEq(govToken.balanceOf(user10), expectedGovTokenBalance);
        assertEq(utilityToken.balanceOf(exchanger), expectedUtilityTokenBalance);
        assertEq(govToken.burnedAmountOfUtilToken(user10), expectedBurnedAmount);
        assertEq(govToken.burnedAmountOfUtilToken(address(user20)), expectedBurnedAmount2);
        assertTrue(votingPowerExchange.authorizationState(user10, nonce) == expectedAuthorizationState);
    }
}
