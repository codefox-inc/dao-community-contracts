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
        vm.startPrank(pauser);
        utilityToken.pause();
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        utilityToken.transfer(user, 1);
        vm.stopPrank();
    }
}
