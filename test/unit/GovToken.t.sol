// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {GovToken} from "src/GovToken.sol";

contract GovTokenTest is Test {
    // instances
    GovToken public govToken;

    // roles
    address public admin = makeAddr("admin");
    address public minter = makeAddr("minter");
    address public burner = makeAddr("burner");

    // users
    address public user = makeAddr("user");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");

    function setUp() public {
        // deploy the GovToken contract
        govToken = new GovToken("AMA Gov Token", "AGT", admin, minter, burner);

        // show the address of the deployed govToken
        console.log("GovToken deployed at:", address(govToken));

        // mint some token for user
        vm.startPrank(minter);
        govToken.mint(user, 100 ether);
        govToken.mint(user2, 100 ether);
        vm.stopPrank();
    }

    /////////////////////////////////////////////////
    ///////////// ERC20 SPECIAL TEST CASES //////////
    /////////////////////////////////////////////////
    function testTokensAreNotTransferrable() public {
        // check the balance of the user
        assertEq(govToken.balanceOf(user), 100 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);

        // try to transfer the token from user to user2
        vm.prank(user2);
        vm.expectRevert(GovToken.TokenTransferNotAllowed.selector);
        govToken.transfer(user, 20 ether);
        vm.prank(user);
        vm.expectRevert(GovToken.TokenTransferNotAllowed.selector);
        govToken.transfer(user2, 10 ether);

        // anyone with no balance cannot call the transfer function either
        vm.expectRevert(GovToken.TokenTransferNotAllowed.selector);
        govToken.transfer(admin, 10 ether);

        // check the balance of the user
        assertEq(govToken.balanceOf(user), 100 ether);

        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);
        console.log("user balance: ", govToken.balanceOf(user));
        console.log("user 2 balance: ", govToken.balanceOf(user2));
    }

    ///
    /// test the minting process of tokens
    ///
    function testMintingCanBeDoneByMinter() public {
        // check the balance of the user
        assertEq(govToken.balanceOf(user), 100 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);

        // mint some token for user
        vm.startPrank(minter);
        govToken.mint(user, 100 ether);
        govToken.mint(user3, 1 ether);
        vm.stopPrank();

        // check the balance of the user
        assertEq(govToken.balanceOf(user), 200 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);
        // check the balance of the user3
        assertEq(govToken.balanceOf(user3), 1 ether);
    }

    function testMintingCannotBeDoneByNonMinter() public {
        // check the balance of the user
        assertEq(govToken.balanceOf(user), 100 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);

        // mint some token for user
        vm.expectRevert();
        govToken.mint(user, 100 ether);
        vm.expectRevert();
        govToken.mint(user3, 1 ether);

        // check the balance of the user
        assertEq(govToken.balanceOf(user), 100 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);
        // check the balance of the user3
        assertEq(govToken.balanceOf(user3), 0 ether);
    }

    function testMintingCanBeDoneByNewMinter() public {
        // check the balance of the user
        assertEq(govToken.balanceOf(user), 100 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);

        // mint some token for user
        vm.startPrank(admin);
        govToken.grantRole(govToken.MINTER_ROLE(), user3);
        vm.stopPrank();

        // mint some token for user
        vm.startPrank(user3);
        govToken.mint(user, 100 ether);
        govToken.mint(user3, 1 ether);
        vm.stopPrank();

        // check the balance of the user
        assertEq(govToken.balanceOf(user), 200 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);
        // check the balance of the user3
        assertEq(govToken.balanceOf(user3), 1 ether);
    }

    function testBurningCanBeDoneByBurner() public {
        // check the balance of the user
        assertEq(govToken.balanceOf(user), 100 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);

        // burn some token for user
        vm.startPrank(burner);
        govToken.burnByBurner(user, 10 ether);
        govToken.burnByBurner(user2, 10 ether);
        vm.stopPrank();

        // check the balance of the user
        assertEq(govToken.balanceOf(user), 90 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 90 ether);
    }

    function testBurningCannotBeDoneByNonBurner() public {
        // check the balance of the user
        assertEq(govToken.balanceOf(user), 100 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);

        vm.expectRevert();
        vm.prank(user);
        govToken.burnByBurner(user2, 10 ether);
        vm.expectRevert();
        vm.prank(user2);
        govToken.burnByBurner(user, 20 ether);
    }

    function testBurningCanBeDoneByNewBurner() public {
        // check the balance of the user
        assertEq(govToken.balanceOf(user), 100 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 100 ether);

        // burn some token for user
        vm.startPrank(admin);
        govToken.grantRole(govToken.BURNER_ROLE(), user3);
        vm.stopPrank();

        // burn some token for user
        vm.startPrank(user3);
        govToken.burnByBurner(user, 10 ether);
        govToken.burnByBurner(user2, 10 ether);
        vm.stopPrank();

        // check the balance of the user
        assertEq(govToken.balanceOf(user), 90 ether);
        // check the balance of the user2
        assertEq(govToken.balanceOf(user2), 90 ether);
    }

    /////////////////////////////////////////////////
    ///////////// ERC20 NORMAL TEST CASES //////////
    /////////////////////////////////////////////////
    function testTheRolesOfTheGovToken() public view {
        // check the roles
        assertTrue(govToken.hasRole(govToken.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(govToken.hasRole(govToken.MINTER_ROLE(), minter));
        assertTrue(govToken.hasRole(govToken.BURNER_ROLE(), burner));
    }

    function testTheTokenInfos() public view {
        // check the token name
        assertEq(govToken.name(), "AMA Gov Token");

        // check the token symbol
        assertEq(govToken.symbol(), "AGT");

        // check the token decimals
        assertEq(govToken.decimals(), 18);
    }
}
