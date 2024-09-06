// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {DeployContracts, DeploymentResult} from "script/DeployContracts.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {AmbassadorNft} from "src/AmbassadorNft.sol";
import {ERC20UpgradeableTokenV1} from "src/ERC20UpgradeableTokenV1.sol";
import {GovToken} from "src/GovToken.sol";
import {VotingPowerExchange} from "src/VotingPowerExchange.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract VotingPwoerExchangeTest is Test {
    // instances
    GovToken public govToken;
    ERC20UpgradeableTokenV1 public utilityToken;
    VotingPowerExchange public votingPowerExchange;
    DeployContracts public dc;

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
    }

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

    ///// basic tests /////
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

    function testVotingPowerExchangesRole() public view {
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
        assertEq(utilityToken.totalSupply(), 111_000 * 1e18);
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

    function testUtilityTokenCanBeTrasnferred() public {
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
        assertEq(vpe.getVotingPowerCap(), 100 * 1e18);
    }

    function teestBasicVotingPowerExchangeInfo() public view {
        (address _utilityToken, address _govToken) = votingPowerExchange.getTokenAddresses();
        assertEq(_govToken, address(govToken));
        assertEq(_utilityToken, address(utilityToken));
    }

    function testConstantValues() public view {
        (bytes32 __EXCHANGE_TYPEHASH, uint256 _PRICISION_FIX, uint256 _PRICISION_FACTOR, uint256 _PRICISION) =
            votingPowerExchange.getConstants();

        assertEq(
            __EXCHANGE_TYPEHASH, keccak256("Exchange(address sender,uint256 amount,bytes32 nonce,uint256 expiration)")
        );
        assertEq(_PRICISION, 1e18);
        assertEq(_PRICISION_FACTOR, 10);
        assertEq(_PRICISION_FIX, 1e9);
    }

    function testVotingPowerCap() public view {
        uint256 cap = votingPowerExchange.getVotingPowerCap();
        assertEq(cap, 100 * 1e18);
    }

    function testSettingVotingPowerCap() public {
        uint256 cap = votingPowerExchange.getVotingPowerCap();
        assertEq(cap, 100 * 1e18);

        uint256 newCap = 110 * 1e18;
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
        votingPowerExchange.setVotingPowerCap(100 * 1e18);
    }

    // this test only run the test for the calculation of increased voting power function
    // 1_000_000 -> 100 voting power
    // 10_000 -> 10 voting power
    // 1_000 -> 3.16 voting power
    // 100 -> 1 voting power
    function testCalculationOfIncreasedVotingPowerWhenCurrentIsZero() public view {
        // when you exchange 1_000_000 utility token, you will get 100 voting power
        uint256 increasedVotingPower = votingPowerExchange.calculateIncreasedVotingPower(1000000 * 1e18, 0);
        assertEq(increasedVotingPower, 100 * 1e18);
        // when you exchange 10_000 utility token, you will get 10 voting power
        increasedVotingPower = votingPowerExchange.calculateIncreasedVotingPower(10000 * 1e18, 0);
        assertEq(increasedVotingPower, 10 * 1e18);
        // when you exchange 1_000 utility token, you will get over 3 voting power
        increasedVotingPower = votingPowerExchange.calculateIncreasedVotingPower(1000 * 1e18, 0);
        assertTrue(increasedVotingPower > 316 * 1e16);
        assertTrue(increasedVotingPower < 317 * 1e16);
        // when you exchange 100 utility token, you will get 1 voting power
        increasedVotingPower = votingPowerExchange.calculateIncreasedVotingPower(100 * 1e18, 0);
        assertEq(increasedVotingPower, 1 * 1e18);
    }

    // this test only run the test for the calculation of increased voting power function
    // increasedVotingPower | currentVotingPower
    // 2000000 | 1000 -> 138.29 voting power
    // 1000000 | 100 -> 99.0 voting power
    // 10000 | 100 -> 90.0 voting power
    // 1000 | 100 -> 2.316 voting power
    // 100 | 100 -> 0.4142 voting power
    function testCalculationOfIncreasedVotingPowerWhenCurrentIsNotZero() public view {
        // when you exchange 2_000_000 utility token and burned token is currently 1000 * 1e18, you will get 138 voting power
        uint256 increasedVotingPower = votingPowerExchange.calculateIncreasedVotingPower(2000000 * 1e18, 1000 * 1e18);
        assertTrue(increasedVotingPower < 1383 * 1e17);
        assertTrue(increasedVotingPower > 1382 * 1e17);
        // when you exchange 1_500_000 utility token with current burned token as 1000 * 1e18, you will get 119 voting power
        increasedVotingPower = votingPowerExchange.calculateIncreasedVotingPower(1500000 * 1e18, 1000 * 1e18);
        assertTrue(increasedVotingPower < 1194 * 1e17);
        assertTrue(increasedVotingPower > 1193 * 1e17);
        // when you exchange 1_000_000 utility token with current burned tokken as 100 * 1e18, you will get 99 voting power
        increasedVotingPower = votingPowerExchange.calculateIncreasedVotingPower(1000000 * 1e18, 100 * 1e18);
        assertTrue(increasedVotingPower < 991 * 1e17);
        assertTrue(increasedVotingPower > 99 * 1e18);
        // when you exchange 10_000 utility token, you will get 10 voting power
        increasedVotingPower = votingPowerExchange.calculateIncreasedVotingPower(10000 * 1e18, 100 * 1e18);
        assertTrue(increasedVotingPower < 905 * 1e16);
        assertTrue(increasedVotingPower > 904 * 1e16);
        // when you exchange 1_000 utility token, you will get over 3 voting power
        increasedVotingPower = votingPowerExchange.calculateIncreasedVotingPower(1000 * 1e18, 100 * 1e18);
        assertTrue(increasedVotingPower < 232 * 1e16);
        assertTrue(increasedVotingPower > 231 * 1e16);
        // when you exchange 100 utility token, you will get 1 voting power
        increasedVotingPower = votingPowerExchange.calculateIncreasedVotingPower(100 * 1e18, 100 * 1e18);
        assertTrue(increasedVotingPower < 415 * 1e15);
        assertTrue(increasedVotingPower > 413 * 1e15);
    }

    // this test only run the test for the calculation of required amount to be burned function
    function testCalculateRequiredAmountToBeBurnedWhenCurrentIsZero() public view {
        // when you exchange 100 voting power, you need to burn 1_000_000 utility token
        uint256 requiredAmount = votingPowerExchange.calculateRequiredAmountToBeBurned(100 * 1e18, 0);
        assertEq(requiredAmount, 100_0000 * 1e18);
        // when you exchange 10 voting power, you need to burn 10_000 utility token
        requiredAmount = votingPowerExchange.calculateRequiredAmountToBeBurned(10 * 1e18, 0);
        assertEq(requiredAmount, 10_000 * 1e18);
        // when you exchange 3 voting power, you need to burn 1_000 utility token
        requiredAmount = votingPowerExchange.calculateRequiredAmountToBeBurned(3 * 1e18, 0);
        assertEq(requiredAmount, 900 * 1e18);
        // when you exchange 1 voting power, you need to burn 100 utility token
        requiredAmount = votingPowerExchange.calculateRequiredAmountToBeBurned(1 * 1e18, 0);
        assertEq(requiredAmount, 100 * 1e18);

        // when you exchange 90 voting power, you need to burn 810_000 utility token
        requiredAmount = votingPowerExchange.calculateRequiredAmountToBeBurned(90 * 1e18, 0);
        assertTrue(requiredAmount < 810_001 * 1e18);
        assertTrue(requiredAmount > 809_999 * 1e18);
    }

    function testCalculateRequiredAmountToBeBurnedWhenCurrentIsNotZero() public view {
        // when you exchange 7 voting power with current burned token as 900 * 1e18, you need to burn 7 utility token
        uint256 requiredAmount = votingPowerExchange.calculateRequiredAmountToBeBurned(7 * 1e18, 900 * 1e18);
        assertEq(requiredAmount, 9100 * 1e18);
        // when you exchange 10 voting power with token burned as 3600 * 1e18, you need to burn 22000 utility token
        requiredAmount = votingPowerExchange.calculateRequiredAmountToBeBurned(10 * 1e18, 3_600 * 1e18);
        assertEq(requiredAmount, 22_000 * 1e18);
        // when you exchange 5 voting power with token burned as 22500 * 1e18, you need to burn 17500 utility token
        requiredAmount = votingPowerExchange.calculateRequiredAmountToBeBurned(5 * 1e18, 22_500 * 1e18);
        assertEq(requiredAmount, 17_500 * 1e18);
        // when you exchange 20 voting power with token burned as 16_900 * 1e18, you need to burn 92_000 utility token
        requiredAmount = votingPowerExchange.calculateRequiredAmountToBeBurned(20 * 1e18, 16_900 * 1e18);
        assertEq(requiredAmount, 92_000 * 1e18);
    }

    /////// Exchange tests ///////
}
