// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DaoGovernor, IGovernor} from "../../src/DaoGovernor.sol";
import {Timelock} from "../../src/Timelock.sol";
import {GovToken} from "../../src/GovToken.sol";
import {ERC20UpgradeableTokenV1} from "src/ERC20UpgradeableTokenV1.sol";
import {VotingPowerExchange} from "src/VotingPowerExchange.sol";
import {DeployContracts, DeploymentResult} from "script/DeployContracts.s.sol";

contract DAOGovernorTest is Test {
    // instances
    DaoGovernor public daoGovernor;
    GovToken public govToken;
    ERC20UpgradeableTokenV1 public utilityToken;
    VotingPowerExchange public votingPowerExchange;
    DeployContracts public dc;

    Timelock public timelock;
    GovToken public token;
    ERC20UpgradeableTokenV1 public erc20;

    DeploymentResult result;

    uint256 public default_anvil_key2 = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    // user for testing exchange
    address public participant = makeAddr("levelUpper2");
    address public participant2;

    // admin roles
    address admin;
    address pauser;
    address minter;
    address burner;
    address manager;
    address exchanger;

    // users for testing
    address public user = makeAddr("user");
    address public executor = makeAddr("executor");

    // values
    uint256 public constant MIN_DELAY = 6 hours; // 6 hours - after a vote passes.
    uint256 public constant VOTING_DELAY = 1 days; // How many time till a proposal vote becomes active
    uint256 public constant VOTING_PERIOD = 1 weeks; // How long a proposal vote is active

    address[] proposers;
    address[] executors;

    // for the proposal
    address[] targets;
    uint256[] values;
    bytes[] calldatas;

    function setUp() public {
        //////////////////////////////
        //// using the deploy contracts script to deploy the contracts
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
        govToken.mint(participant2, 6 * 1e18);
        govToken.mint(user, 4 * 1e18);
        utilityToken.mint(participant2, 10_000 * 1e18);
        vm.stopPrank();

        // delegate the voting power to the participant2 and user themselves
        vm.prank(participant2);
        govToken.delegate(participant2);
        vm.prank(user);
        govToken.delegate(user);
        //////////////////////////////

        // deploy the timelock
        timelock = new Timelock(MIN_DELAY, proposers, executors, admin); // empty array means anyone can propose and anyone can execute

        daoGovernor = new DaoGovernor(govToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE(); // keccak256("PROPOSER_ROLE")
        bytes32 executorRole = timelock.EXECUTOR_ROLE(); // keccak256("EXECUTOR_ROLE")
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE(); // keccak256("DEFAULT_ADMIN_ROLE")

        vm.startPrank(admin);
        // only the governor can propose
        timelock.grantRole(proposerRole, address(daoGovernor));
        // anybody can execute
        timelock.grantRole(executorRole, address(0)); // anybody can execute the proposal, this should not be done in production
        timelock.revokeRole(adminRole, admin); // user is the admin and we do not need a single pointo of failure

        govToken.grantRole(govToken.MINTER_ROLE(), address(timelock));
        vm.stopPrank();
    }

    function testCannotMintTokenWithoutDaoGovernance() public {
        vm.prank(participant2);
        vm.expectRevert();
        govToken.mint(participant2, 1e18);
        vm.stopPrank();
    }

    function testGovernorCanGetProposedAndMintUtilityToken() public {
        address ourAddress = makeAddr("ourAddress");
        string memory description = "mint 1000e18 to our address";
        bytes memory encodeFunctionData = abi.encodeWithSignature("mint(address,uint256)", ourAddress, 1000e18);
        targets.push(address(govToken)); // this is the calling address
        values.push(0); // this means no value is sent to the target address
        calldatas.push(encodeFunctionData); // this is the data of the function call

        // check the balance and the voting power of the participant2
        console.log(govToken.balanceOf(user));
        console.log(govToken.getVotes(user));
        // 1. propose to the dao
        // at least 1 block later(12 seconds)
        vm.warp(block.timestamp + 15);
        vm.roll(block.number + 1);

        vm.startPrank(user);
        uint256 proposalId = daoGovernor.propose(targets, values, calldatas, description);
        vm.stopPrank();

        // view the state
        uint256 state = uint256(daoGovernor.state(proposalId));
        console.log("state1", state);

        // time lasts
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + 1 + 1);

        uint256 state2 = uint256(daoGovernor.state(proposalId));
        console.log("state2", state2);

        // 2. vote
        string memory reason = "your proposal is always right!";
        vm.prank(participant2);
        daoGovernor.castVoteWithReason(proposalId, 1, reason);

        // 3. queue
        // time lasts
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + 50400 + 1);
        uint256 state3 = uint256(daoGovernor.state(proposalId));
        console.log("state3", state3);

        // 4. queue the tx
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        daoGovernor.queue(targets, values, calldatas, descriptionHash);

        // 5. execute
        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY / 12 + 1);
        daoGovernor.execute(targets, values, calldatas, descriptionHash);

        console.log("token balance of our address: ", govToken.balanceOf(ourAddress));
        assertEq(govToken.balanceOf(ourAddress), 1000e18);

        assertEq(uint256(daoGovernor.state(proposalId)), uint256(IGovernor.ProposalState.Executed));
    }
}
