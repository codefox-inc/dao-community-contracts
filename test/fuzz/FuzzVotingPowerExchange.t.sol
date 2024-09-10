// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {AmbassadorNft} from "src/AmbassadorNft.sol";
import {DeployContracts, DeploymentResult} from "script/DeployContracts.s.sol";
import {ERC20UpgradeableTokenV1} from "src/ERC20UpgradeableTokenV1.sol";
import {GovToken} from "src/GovToken.sol";
import {VotingPowerExchange} from "src/VotingPowerExchange.sol";
import {VotingPowerExchangeTestHelper} from "../integration/utils/VotingPowerExchangeTestHelper.t.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

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

    function testFuzz_exchange(uint256 amount) public {
    }
}
