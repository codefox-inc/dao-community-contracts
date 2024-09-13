// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {GovToken} from "src/GovToken.sol";

contract GovTokenTest is Test {
    // instances
    GovToken public govToken;
    // private key
    uint256 public constant DEFAULT_ANVIL_KEY2 = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    address public participant2;

    // roles
    address public admin = makeAddr("admin");
    address public minter = makeAddr("minter");
    address public burner = makeAddr("burner");
    address public votingPowerExchange = makeAddr("votingPowerExchange");

    // users
    address public user = makeAddr("user");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");

    function setUp() public {
        // deploy the GovToken contract
        govToken = new GovToken("AMA Gov Token", "AGT", admin, minter, burner, votingPowerExchange);

        // show the address of the deployed govToken
        console.log("GovToken deployed at:", address(govToken));

        // mint some token for user
        vm.startPrank(minter);
        govToken.mint(user, 100 ether);
        govToken.mint(user2, 100 ether);
        vm.stopPrank();
        participant2 = vm.addr(DEFAULT_ANVIL_KEY2);
    }

    /////////////////////////////////////////////////
    ///////////// ERC20 SPECIAL TEST CASES //////////
    /////////////////////////////////////////////////
    ///
    /// test if default admin cannot be zero
    ///
    function testGovTokenDefaultAdminCannotBeZero() public {
        vm.expectRevert(GovToken.DefaultAdminCannotBeZero.selector);
        GovToken govToken2 = new GovToken("AMA Gov Token", "AGT", address(0), minter, burner, votingPowerExchange);
        assertEq(address(govToken2), address(1));
    }

    function testClockMode() public view {
        string memory clockMode = govToken.CLOCK_MODE();

        // check if the clock mode is "mode=timestamp"
        assertEq(clockMode, "mode=timestamp", "CLOCK_MODE should return 'mode=timestamp'");
    }

    ///
    /// test the token transfer is not allowed
    ///
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

    function testVotingPowerExchangeCanCallSetBurnedAmountOfUtilToken() public {
        vm.startPrank(votingPowerExchange);
        govToken.setBurnedAmountOfUtilToken(user, 100 ether);
        govToken.setBurnedAmountOfUtilToken(user2, 100 ether);
        vm.stopPrank();

        // check the burned amount of the user
        assertEq(govToken.burnedAmountOfUtilToken(user), 100 ether);
        // check the burned amount of the user2
        assertEq(govToken.burnedAmountOfUtilToken(user2), 100 ether);
    }

    function testNonRoleCannotCallSetBurnedAmountOfUtilToken() public {
        vm.startPrank(user);
        vm.expectRevert();
        govToken.setBurnedAmountOfUtilToken(user, 100 ether);
        vm.expectRevert();
        govToken.setBurnedAmountOfUtilToken(user2, 100 ether);
        vm.stopPrank();

        // check the burned amount of the user
        assertEq(govToken.burnedAmountOfUtilToken(user), 0 ether);
        // check the burned amount of the user2
        assertEq(govToken.burnedAmountOfUtilToken(user2), 0 ether);
    }

    function testSetBurnedAmountOfUtilTokenEvent() public {
        vm.startPrank(votingPowerExchange);
        vm.expectEmit();
        emit GovToken.burnedAmountOfUtilTokenSet(user, 100 ether);
        govToken.setBurnedAmountOfUtilToken(user, 100 ether);
        vm.expectEmit();
        emit GovToken.burnedAmountOfUtilTokenSet(user2, 100 ether);
        govToken.setBurnedAmountOfUtilToken(user2, 100 ether);
        vm.stopPrank();

        // check the burned amount of the user
        assertEq(govToken.burnedAmountOfUtilToken(user), 100 ether);
        // check the burned amount of the user2
        assertEq(govToken.burnedAmountOfUtilToken(user2), 100 ether);
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

    function testNonces() public {
        // nonce should be 0
        assertEq(govToken.nonces(user), 0, "Initial nonce should be 0");

        // simulate a permit to increase the nonce
        uint256 privateKey = DEFAULT_ANVIL_KEY2;
        address owner = vm.addr(privateKey);
        uint256 deadline = block.timestamp + 1 hours;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    govToken.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            address(12),
                            1 ether,
                            0,
                            deadline
                        )
                    )
                )
            )
        );

        govToken.permit(owner, address(12), 1 ether, deadline, v, r, s);

        // check if nonce is incremented after permit
        assertEq(govToken.nonces(owner), 1, "Nonce should be incremented after permit");

        // other user's nonce should still be 0
        assertEq(govToken.nonces(user), 0, "Other user's nonce should still be 0");
        // transfer the token to user2 on behalf of owner will fail
        vm.prank(address(12));
        vm.expectRevert(GovToken.TokenTransferNotAllowed.selector);
        govToken.transferFrom(owner, user2, 1 ether);
        // In fact ERC20Permit is technically not used in this contract due to the token's untransferability.
    }

    function testDelegateBySig() public {
        uint256 privateKey = DEFAULT_ANVIL_KEY2;
        address owner = vm.addr(privateKey);
        // Initial delegate should be address(0)
        assertEq(govToken.delegates(owner), address(0), "Initial delegate should be address(0)");
        assertEq(govToken.nonces(owner), 0, "Initial nonce should be 0");

        // Simulate a delegateBySig to change the delegate
        uint256 nonce = govToken.nonces(owner);
        uint256 expiry = block.timestamp + 1 hours;
        bytes32 DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
        // sign the delegateBySig by owner
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    govToken.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(DELEGATION_TYPEHASH, address(this), nonce, expiry))
                )
            )
        );

        govToken.delegateBySig(address(this), nonce, expiry, v, r, s);

        // Check if delegate is changed after delegateBySig
        assertEq(govToken.delegates(owner), address(this), "Delegate should be changed after delegateBySig");

        // Check if nonce is incremented after delegateBySig
        assertEq(govToken.nonces(owner), 1, "Nonce should be incremented after delegateBySig");

        // Other user's delegate should still be address(0)
        assertEq(govToken.delegates(user), address(0), "Other user's delegate should still be address(0)");
    }

    function testDelegates() public view {
        // check the initial delegate of the user
        assertEq(govToken.delegates(user), address(0), "Initial delegate should be address(0)");

        // check the initial delegate of the user2
        assertEq(govToken.delegates(user2), address(0), "Initial delegate should be address(0)");

        // check the initial delegate of the user3
        assertEq(govToken.delegates(user3), address(0), "Initial delegate should be address(0)");
    }

    function testInitialVotes() public view {
        // check the initial votes of the user
        assertEq(govToken.getVotes(user), 0, "Initial votes should be 0");

        // check the initial votes of the user2
        assertEq(govToken.getVotes(user2), 0, "Initial votes should be 0");

        // check the initial votes of the user3
        assertEq(govToken.getVotes(user3), 0, "Initial votes should be 0");
    }

    function testVotesAfterSelfDelegate() public {
        // check the initial votes of the user
        assertEq(govToken.getVotes(user), 0, "Initial votes should be 0");
        // test the votes of the user after delegate to himself
        vm.startPrank(user);
        govToken.delegate(user);
        vm.stopPrank();

        // check the votes of the user
        assertEq(govToken.getVotes(user), 100 ether, "Votes should be 100 ether");

        // check the initial votes of the user3
        assertEq(govToken.getVotes(user3), 0, "Initial votes should be 0");
    }

    function testVotesAfterDelegateToOther() public {
        // check the initial votes of the user
        assertEq(govToken.getVotes(user), 0, "Initial votes should be 0");
        // check the initial votes of the user2
        assertEq(govToken.getVotes(user2), 0, "Initial votes should be 0");

        // test the votes of the user after delegate to user2
        vm.prank(user2);
        govToken.delegate(user2);

        assertEq(govToken.getVotes(user2), 100 ether, "Votes should be 100 ether");

        vm.prank(user);
        govToken.delegate(user2);

        // check the votes of the user
        assertEq(govToken.getVotes(user), 0, "Votes should be 0");
        // check the votes of the user2
        assertEq(govToken.getVotes(user2), 200 ether, "Votes should be 100 ether");
    }

    function testClock() public {
        // set up a timestamp
        uint256 currentTimestamp = 1678901234; // 2023-03-15 12:33:54 UTC
        vm.warp(currentTimestamp);

        // call clock() function
        uint48 clockValue = govToken.clock();

        // returned value is current block timestamp
        assertEq(clockValue, uint48(currentTimestamp), "clock() should return current block timestamp");

        // check the timestamp change
        uint256 newTimestamp = currentTimestamp + 3600; // 增加一小时
        vm.warp(newTimestamp);

        // call clock() function again
        uint48 newClockValue = govToken.clock();

        // check if the returned value is the new timestamp
        assertEq(newClockValue, uint48(newTimestamp), "clock() should return updated block timestamp");

        // check if the clock value is increased
        assertGt(newClockValue, clockValue, "New clock value should be greater than the previous one");
    }
}
