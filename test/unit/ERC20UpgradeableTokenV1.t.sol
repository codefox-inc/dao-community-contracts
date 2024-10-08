// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {UnsafeUpgrades, Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IAccessControl} from
    "openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {ERC20UpgradeableTokenV1} from "src/ERC20UpgradeableTokenV1.sol";
import {ERC20UpgradeableTokenV2} from "../mocks/ERC20UpgradeableTokenV2.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

contract ERC20UpgradeableTokenV1Test is Test {
    // instances of contracts
    address public proxy;
    ERC20UpgradeableTokenV1 public token;
    ERC20UpgradeableTokenV2 public upgradedToken;

    // admin roles
    address public admin = makeAddr("admin");
    address public pauser = makeAddr("pauser");
    address public minter = makeAddr("minter");
    address public burner = makeAddr("burner");

    // users
    address public user = makeAddr("user");
    address public holder = makeAddr("holder");

    function setUp() public {
        // deploy the upgradeable token contract using the OpenZeppelin Upgrades library
        // proxy = Upgrades.deployUUPSProxy(
        //     "ERC20UpgradeableTokenV1.sol",
        //     abi.encodeCall(
        //         ERC20UpgradeableTokenV1.initialize, ("AMA coin", "AMA", admin, pauser, minter, burner, admin)
        //     )
        // );

        address implementation = address(new ERC20UpgradeableTokenV1());
        proxy = UnsafeUpgrades.deployUUPSProxy(
            implementation,
            abi.encodeCall(
                ERC20UpgradeableTokenV1.initialize, ("AMA coin", "AMA", admin, pauser, minter, burner, admin)
            )
        );
        // UnsafeUpgrades method is used to deploy the UUPS in test environment not in production
        // address implementation = address(new ERC20UpgradeableTokenV1());
        // address proxy = Upgrades.deployUUPSProxy(
        //     implementation,
        //     abi.encodeCall(
        //         ERC20UpgradeableTokenV1.initialize, ("AMA coin", "AMA", admin, pauser, minter, burner, admin)
        //     )
        // );
        // show the address of the deployed proxy
        console.log("Proxy deployed at:", proxy);

        // initialize the token instance by using the proxy address
        token = ERC20UpgradeableTokenV1(proxy);

        // only mint some token for the token `holder`
        vm.prank(minter);
        token.mint(holder, 1000 ether);
    }

    /**
     * @dev These are the special test cases derived from the modifications of the original OpenZeppelin ERC20 token contract.
     */
    ////////////////////////////////////////////////////
    ///////////// ERC20 SPECIAL TEST CASES /////////////
    ////////////////////////////////////////////////////
    ///
    /// test default admin cannot be zero
    ///
    function testDefaultAdminCannotBeZero() public {
        address implementation2 = address(new ERC20UpgradeableTokenV1());
        vm.expectRevert(ERC20UpgradeableTokenV1.DefaultAdminCannotBeZero.selector);
        address proxy2 = UnsafeUpgrades.deployUUPSProxy(
            implementation2,
            abi.encodeCall(
                ERC20UpgradeableTokenV1.initialize, ("AMA coin", "AMA", address(0), pauser, minter, burner, admin)
            )
        );
        console.log("Proxy2 deployed at:", proxy2);
    }

    ///
    /// test burning the tokens
    // ///
    function testSucceedingToBurnTokens() public {
        vm.prank(burner);
        token.burnByBurner(holder, 100 ether);
        assertEq(token.balanceOf(holder), 900 ether);
        vm.prank(burner);
        token.burnByBurner(holder, 900 ether);
        assertEq(token.balanceOf(holder), 0 ether);
    }

    function testFailingToBurnTokens() public {
        vm.expectRevert();
        vm.prank(holder);
        token.burnByBurner(holder, 100 ether);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, holder, token.BURNER_ROLE()
            )
        );
        vm.prank(user);
        token.burnByBurner(holder, 900 ether);
        // check that no token was burned
        assertEq(token.balanceOf(holder), 1000 ether);
    }

    /**
     * @dev These are the normal test cases for an ERC20 token.
     */
    ///////////////////////////////////////////////////
    ///////////// ERC20 NORMAL TEST CASES /////////////
    ///////////////////////////////////////////////////

    ///
    /// test basic token setups
    ///
    function testShowingBasicTokenInfo() public view {
        assertEq(token.name(), "AMA coin");
        assertEq(token.symbol(), "AMA");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 1000 ether);
    }

    ///
    /// test roles are set correctly
    ///
    function testRolesAreSetCorrectly() public view {
        assertEq(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin), true);
        assertEq(token.hasRole(token.PAUSER_ROLE(), pauser), true);
        assertEq(token.hasRole(token.MINTER_ROLE(), minter), true);
        // console.logBytes32(token.BURNER_ROLE());
        // console.log(burner);
        // assertEq(token.hasRole(token.BURNER_ROLE(), burner), true);
        assertEq(token.hasRole(token.UPGRADER_ROLE(), admin), true);
    }

    ///
    /// test granting roles
    ///
    function testGrantRoles() public {
        console.log("admin has role:", token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        vm.startPrank(admin);
        token.grantRole(token.PAUSER_ROLE(), user);
        assertEq(token.hasRole(token.PAUSER_ROLE(), user), true);
        vm.stopPrank();
    }

    ///
    /// test granting and revoking roles
    ///
    function testGrantingAndRevokingRoles() public {
        vm.startPrank(admin);
        token.grantRole(token.PAUSER_ROLE(), user);
        assertEq(token.hasRole(token.PAUSER_ROLE(), user), true);
        token.revokeRole(token.PAUSER_ROLE(), user);
        assertEq(token.hasRole(token.PAUSER_ROLE(), user), false);
        vm.stopPrank();
    }

    ///
    /// test approving and spending
    ///
    function testApprovingSpending() public {
        vm.prank(holder);
        token.approve(user, 100 ether);
        assertEq(token.allowance(holder, user), 100 ether);
    }

    ///
    /// test approving and transferring
    ///
    function testApprovingAndTransferFrom() public {
        vm.prank(holder);
        token.approve(user, 100 ether);
        vm.prank(user);
        token.transferFrom(holder, user, 100 ether);

        assertEq(token.balanceOf(holder), 900 ether);
        assertEq(token.balanceOf(user), 100 ether);
        assertEq(token.allowance(holder, user), 0 ether);
    }

    ///
    /// test approving all and transferring from all
    ///
    function testApprovingAllAndTransferFromAll() public {
        vm.prank(holder);
        token.approve(user, 1000 ether);
        vm.prank(user);
        token.transferFrom(holder, user, 1000 ether);

        assertEq(token.balanceOf(holder), 0 ether);
        assertEq(token.balanceOf(user), 1000 ether);
        assertEq(token.allowance(holder, user), 0 ether);
    }

    ///
    /// test approving all and transferring from half
    ///
    function testApprovingAllAndTransferFromHalf() public {
        vm.prank(holder);
        token.approve(user, 1000 ether);
        vm.prank(user);
        token.transferFrom(holder, user, 450 ether);

        assertEq(token.balanceOf(holder), 550 ether);
        assertEq(token.balanceOf(user), 450 ether);
        assertEq(token.allowance(holder, user), 550 ether);
    }

    ///
    /// test sending tokens
    ///
    function testSendingTokens() public {
        vm.prank(minter);
        token.mint(address(this), 1000);
        assertEq(token.balanceOf(address(this)), 1000);
        token.transfer(user, 100);
        assertEq(token.balanceOf(address(this)), 900);
        assertEq(token.balanceOf(user), 100);
    }

    ///
    /// test pausing and unpausing the token
    ///
    function testPausingAndUnpausingSuccessfully() public {
        vm.startPrank(pauser);
        token.pause();
        assertEq(token.paused(), true);
        token.unpause();
        assertEq(token.paused(), false);
        vm.stopPrank();
    }

    function testWhenPausedNoMintingOrTransferringIsAllowed() public {
        vm.prank(pauser);
        token.pause();
        assertEq(token.paused(), true);

        vm.prank(minter);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        token.mint(user, 100);
        vm.startPrank(holder);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        token.transfer(user, 100);
        vm.stopPrank();
    }

    /// test upgradeability of the token
    ///
    function testUpgradeabilityOfToken() public {
        address treasuryAddr = makeAddr("treasury");
        address newAdmin = makeAddr("newAdmin");
        vm.startPrank(admin);
        // Upgrades.upgradeProxy(
        //     address(token),
        //     "ERC20UpgradeableTokenV2.sol",
        //     abi.encodeCall(ERC20UpgradeableTokenV2.initializeV2, (treasuryAddr, newAdmin))
        // );
        ////////////////////////////
        // deploy the upgraded implementation token contract
        address newImplementation = address(new ERC20UpgradeableTokenV2());
        // upgrade the token using the OpenZeppelin Upgrades library
        UnsafeUpgrades.upgradeProxy(
            address(token),
            newImplementation,
            abi.encodeWithSelector(ERC20UpgradeableTokenV2.initializeV2.selector, treasuryAddr, newAdmin)
        );

        // show the address of the deployed proxy
        console.log("Proxy deployed at:", proxy);
        vm.stopPrank();

        // initialize the upgraded token instance by using the proxy address
        upgradedToken = ERC20UpgradeableTokenV2(proxy);

        // check the token name and symbol
        assertEq(upgradedToken.name(), "AMA coin");
        assertEq(upgradedToken.symbol(), "AMA");

        // check the total supply of the token
        assertEq(upgradedToken.totalSupply(), 1000 ether);

        // check the balance of the holder
        assertEq(upgradedToken.balanceOf(holder), 1000 ether);

        // check the roles of the token
        assertEq(upgradedToken.hasRole(upgradedToken.DEFAULT_ADMIN_ROLE(), admin), true);
        assertEq(upgradedToken.hasRole(upgradedToken.PAUSER_ROLE(), pauser), true);
        assertEq(upgradedToken.hasRole(upgradedToken.MINTER_ROLE(), minter), true);
        // assertEq(upgradedToken.hasRole(upgradedToken.BURNER_ROLE(), burner), true);
        assertEq(upgradedToken.hasRole(upgradedToken.UPGRADER_ROLE(), admin), true);
        assertEq(upgradedToken.hasRole(upgradedToken.TREASURY_ROLE(), treasuryAddr), true);
        assertEq(upgradedToken.getTreasury(), treasuryAddr);
        console.log("treasuryAddr: ", treasuryAddr);
    }
}
