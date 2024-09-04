// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {AmbassadorNft} from "src/AmbassadorNft.sol";

contract AmbassadorTest is Test {
    // instances
    AmbassadorNft public ambassadorNft;

    // roles
    address public admin = makeAddr("admin");
    address public minter = makeAddr("minter");
    address public burner = makeAddr("burner");
    address public uriSetter = makeAddr("uriSetter");

    // 4 kinds of users
    address public whiteUser = makeAddr("whiteUser");
    address public blueUser = makeAddr("blueUser");
    address public silverUser = makeAddr("silverUser");
    address public blackUser = makeAddr("blackUser");
    address public user = makeAddr("user");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");

    function setUp() public {
        // deploy the AmbassadorNft contract
        ambassadorNft = new AmbassadorNft(admin, minter, burner, uriSetter);

        // show the address of the deployed ambassador
        console.log("Ambassador deployed at:", address(ambassadorNft));

        // mint some token for user
        vm.startPrank(minter);
        console.log(msg.sender, minter);
        ambassadorNft.mint(user, 0, 1, "");
        ambassadorNft.mint(user2, 1, 1, "");
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////
    ///////////// ERC1155 SPECIAL TEST CASES /////////////
    //////////////////////////////////////////////////////
    ///
    /// test the roles of the ambassadorNft
    ///
    function testTokenRoles() public view {
        // check the roles
        assertTrue(ambassadorNft.hasRole(ambassadorNft.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(ambassadorNft.hasRole(ambassadorNft.MINTER_ROLE(), minter));
        assertTrue(ambassadorNft.hasRole(ambassadorNft.BURNER_ROLE(), burner));
        assertTrue(ambassadorNft.hasRole(ambassadorNft.URI_SETTER_ROLE(), uriSetter));
    }

    ///
    /// test the minting process of tokens
    ///
    function testMintingTokensSuccessfully() public {
        // mint some tokens
        vm.startPrank(minter);
        ambassadorNft.mint(whiteUser, 0, 1, "");
        ambassadorNft.mint(blueUser, 1, 2, "");
        ambassadorNft.mint(minter, 5, 1, "");
        vm.stopPrank();

        // check the balances
        assertEq(ambassadorNft.balanceOf(whiteUser, 0), 1);
        assertEq(ambassadorNft.balanceOf(blueUser, 1), 2);
        assertEq(ambassadorNft.balanceOf(minter, 5), 1);
    }

    function testMintingTokenWillFailByNonMinter() public {
        // mint some tokens
        vm.expectRevert();
        ambassadorNft.mint(whiteUser, 0, 1, "");
        vm.expectRevert();
        ambassadorNft.mint(blueUser, 1, 1, "");
        vm.expectRevert();
        ambassadorNft.mint(blueUser, 2, 1, "");
    }

    function testMintingTokenWillSucceedByNewMinter() public {
        // when non-minter mint some tokens
        vm.startPrank(blackUser);
        vm.expectRevert();
        ambassadorNft.mint(blackUser, 0, 1, "");
        vm.stopPrank();

        // mint some tokens
        vm.startPrank(admin);
        ambassadorNft.grantRole(ambassadorNft.MINTER_ROLE(), blackUser);
        vm.stopPrank();

        vm.startPrank(blackUser);
        ambassadorNft.mint(whiteUser, 0, 1, "");
        ambassadorNft.mint(blueUser, 1, 1, "");
        ambassadorNft.mint(silverUser, 2, 1, "");
        vm.stopPrank();

        // check the balances
        assertEq(ambassadorNft.balanceOf(whiteUser, 0), 1);
        assertEq(ambassadorNft.balanceOf(blueUser, 1), 1);
        assertEq(ambassadorNft.balanceOf(silverUser, 2), 1);
    }

    ///
    /// test the burning process of tokens
    ///
    function testBurningTokenSuccessfully() public {
        // mint some tokens
        vm.startPrank(minter);
        ambassadorNft.mint(whiteUser, 0, 1, "");
        ambassadorNft.mint(blueUser, 1, 2, "");
        ambassadorNft.mint(minter, 5, 1, "");
        vm.stopPrank();

        // burn some tokens
        vm.startPrank(burner);
        ambassadorNft.burn(whiteUser, 0, 1);
        ambassadorNft.burn(blueUser, 1, 1);
        ambassadorNft.burn(minter, 5, 1);
        vm.stopPrank();

        // check the balances
        assertEq(ambassadorNft.balanceOf(whiteUser, 0), 0);
        assertEq(ambassadorNft.balanceOf(blueUser, 1), 1);
        assertEq(ambassadorNft.balanceOf(minter, 5), 0);
    }

    function testBurningTokenWillFailByNonBurner() public {
        // mint some tokens
        vm.startPrank(minter);
        ambassadorNft.mint(whiteUser, 0, 1, "");
        ambassadorNft.mint(blueUser, 1, 1, "");
        ambassadorNft.mint(blueUser, 2, 1, "");
        vm.stopPrank();

        // burn some tokens
        vm.expectRevert();
        ambassadorNft.burn(whiteUser, 0, 1);
        vm.expectRevert();
        ambassadorNft.burn(blueUser, 1, 1);
        vm.expectRevert();
        ambassadorNft.burn(blueUser, 2, 1);
    }

    function testBurningTokenWillSucceedByNewBurner() public {
        // mint some tokens
        vm.startPrank(minter);
        ambassadorNft.mint(whiteUser, 0, 1, "");
        ambassadorNft.mint(blueUser, 1, 1, "");
        ambassadorNft.mint(blueUser, 2, 1, "");
        vm.stopPrank();

        // burn some tokens
        vm.startPrank(admin);
        ambassadorNft.grantRole(ambassadorNft.BURNER_ROLE(), blackUser);
        vm.stopPrank();

        vm.startPrank(blackUser);
        ambassadorNft.burn(whiteUser, 0, 1);
        ambassadorNft.burn(blueUser, 1, 1);
        ambassadorNft.burn(blueUser, 2, 1);
        vm.stopPrank();

        // check the balances
        assertEq(ambassadorNft.balanceOf(whiteUser, 0), 0);
        assertEq(ambassadorNft.balanceOf(blueUser, 1), 0);
        assertEq(ambassadorNft.balanceOf(blueUser, 2), 0);
    }

    /////////////////////////////////////////////////////
    ///////////// ERC1155 NORMAL TEST CASES /////////////
    /////////////////////////////////////////////////////

    function testSetURI() public {
        // set the URI
        vm.prank(uriSetter);
        ambassadorNft.setURI("https://example.com/{id}.json");

        // check the URI
        assertEq(ambassadorNft.uri(0), "https://example.com/{id}.json");
        assertEq(ambassadorNft.uri(1), "https://example.com/{id}.json");
        assertEq(ambassadorNft.uri(5), "https://example.com/{id}.json");
    }

    function testSetURIByNonUriSetter() public {
        // set the URI by non-uriSetter
        vm.expectRevert();
        ambassadorNft.setURI("https://example.com/{id}.json");
    }

    function testBalanceOfWorks() public view {
        // check the balances
        assertEq(ambassadorNft.balanceOf(user, 0), 1);
        assertEq(ambassadorNft.balanceOf(user, 1), 0);
        assertEq(ambassadorNft.balanceOf(user2, 0), 0);
        assertEq(ambassadorNft.balanceOf(user2, 1), 1);
    }

    function testBalanceOfBatchWorks() public view {
        // check the balances
        uint256[] memory ids = new uint256[](2);
        address[] memory accounts = new address[](2);
        ids[0] = 0;
        ids[1] = 1;
        accounts[0] = user;
        accounts[1] = user2;

        uint256[] memory balances = ambassadorNft.balanceOfBatch(accounts, ids);

        assertEq(balances[0], 1);
        assertEq(balances[1], 1);
    }

    function testTransferWillWork() public {
        // check the balances
        assertEq(ambassadorNft.balanceOf(user, 0), 1);
        assertEq(ambassadorNft.balanceOf(user2, 0), 0);

        // transfer the token
        vm.prank(user);
        ambassadorNft.safeTransferFrom(user, user3, 0, 1, "");

        // check the balances
        assertEq(ambassadorNft.balanceOf(user, 0), 0);
        assertEq(ambassadorNft.balanceOf(user3, 0), 1);
    }
}
