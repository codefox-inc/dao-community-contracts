// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {AmbassadorNft} from "src/AmbassadorNft.sol";
import {IERC1155, IERC1155MetadataURI, ERC165} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

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
    /// test the constructor validation
    ///
    function testConstructorWillRevertIfAdminIsZero() public {
        vm.expectRevert();
        new AmbassadorNft(address(0), minter, burner, uriSetter);
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

    ///
    /// test the minting process of tokens by non-minter
    ///
    function testMintingTokenWillFailByNonMinter() public {
        // mint some tokens
        vm.expectRevert();
        ambassadorNft.mint(whiteUser, 0, 1, "");
        vm.expectRevert();
        ambassadorNft.mint(blueUser, 1, 1, "");
        vm.expectRevert();
        ambassadorNft.mint(blueUser, 2, 1, "");
    }

    ///
    /// test the minting process of tokens by new minter
    ///
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

    ///
    /// test the burning process of tokens by non-burner
    ///
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

    ///
    /// test the burning process of tokens by new burner
    ///
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

    function testBurnBatchCanBeCalledByBurner() public {
        // prepare test data
        address testAccount = address(3);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 3;
        ids[1] = 4;
        uint256[] memory values = new uint256[](2);
        values[0] = 1;
        values[1] = 12;
        uint256[] memory burningValues = new uint256[](2);
        burningValues[0] = 1;
        burningValues[1] = 11;

        // mint some tokens
        vm.startPrank(minter);
        ambassadorNft.mintBatch(testAccount, ids, values, "");
        vm.stopPrank();

        // try to call burnBatch
        vm.startPrank(burner);
        ambassadorNft.burnBatch(testAccount, ids, burningValues);
        vm.stopPrank();

        // check the balances
        assertEq(ambassadorNft.balanceOf(testAccount, 3), 0);
        assertEq(ambassadorNft.balanceOf(testAccount, 4), 1);
    }

    function testBurnBatchWillFailByNonBurner() public {
        // prepare test data
        address testAccount = address(3);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 3;
        ids[1] = 4;
        uint256[] memory values = new uint256[](2);
        values[0] = 1;
        values[1] = 12;
        uint256[] memory burningValues = new uint256[](2);
        burningValues[0] = 1;
        burningValues[1] = 11;

        // mint some tokens
        vm.startPrank(minter);
        ambassadorNft.mintBatch(testAccount, ids, values, "");
        vm.stopPrank();
        // try to call burnBatch
        vm.startPrank(blackUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, blackUser, ambassadorNft.BURNER_ROLE()
            )
        );
        ambassadorNft.burnBatch(testAccount, ids, burningValues);
        vm.stopPrank();
    }

    /////////////////////////////////////////////////////
    ///////////// ERC1155 NORMAL TEST CASES /////////////
    /////////////////////////////////////////////////////

    ///
    /// test the setting process of URI
    ///
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

    ///
    /// test the balanceOfBatch function
    ///
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

    ///
    /// test the transfer process of tokens
    ///
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

    ///
    /// test the mintBatch function
    ///
    function testMintBatchWillWork() public {
        // construct the ids and amounts arrays
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 3;
        amounts[0] = 1;
        ids[1] = 4;
        amounts[1] = 1;

        // mint some tokens
        vm.startPrank(minter);
        ambassadorNft.mintBatch(user, ids, amounts, "");
        vm.stopPrank();

        // check the balances
        assertEq(ambassadorNft.balanceOf(user, 3), 1);
        assertEq(ambassadorNft.balanceOf(user, 4), 1);
    }

    ///
    /// test supportsInterface function
    ///
    function testSupportsInterface() public view {
        // check the supportsInterface function
        assertEq(ambassadorNft.supportsInterface(type(IERC1155).interfaceId), true);
        assertEq(ambassadorNft.supportsInterface(type(IERC1155MetadataURI).interfaceId), true);
        assertEq(ambassadorNft.supportsInterface(type(IAccessControl).interfaceId), true);
        assertEq(ambassadorNft.supportsInterface(type(ERC165).interfaceId), true);
    }
}
