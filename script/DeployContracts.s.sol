// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {console, Script} from "forge-std/Script.sol";
import {Upgrades, UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IAccessControl} from
    "openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {ERC20UpgradeableTokenV1} from "src/ERC20UpgradeableTokenV1.sol";
import {VotingPowerExchange} from "src/VotingPowerExchange.sol";
import {GovToken} from "src/GovToken.sol";

struct DeploymentResult {
    address utilityToken;
    address govToken;
    address exchange;
    address admin;
    address pauser;
    address minter;
    address burner;
    address manager;
    address exchanger;
    uint256 deployerKey;
    uint256 participant;
}

contract DeployContracts is Script {
    // contracts instances
    GovToken public govToken;
    ERC20UpgradeableTokenV1 public utilityToken;
    VotingPowerExchange public votingPowerExchange;

    DeploymentResult public result;

    // anvil's default private key
    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public constant DEFAULT_ANVIL_KEY2 = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    // admin roles
    address public admin;
    address public pauser;
    address public minter;
    address public burner;
    address public manager;
    address public exchanger;
    address public upgrader;
    address public defender;
    address public constant ZERO_ADDRESS = address(0);

    function run() public returns (DeploymentResult memory) {
        // local netwrok
        if (block.chainid == 31337) {
            console.log("Deploying contracts on the local testnet");
            result = deploymentsOnLocalNetwork();
        } else if (block.chainid == 84532) {
            console.log("Deploying contracts on the base testnet");

            result = deploymentsOnBaseSepolia();
        } else if (block.chainid == 8453) {
            console.log("Deploying contracts on the base mainnet");

            result = DeploymentResult({
                utilityToken: ZERO_ADDRESS,
                govToken: ZERO_ADDRESS,
                exchange: ZERO_ADDRESS,
                admin: vm.addr(vm.envUint("PRIVATE_KEY")),
                pauser: ZERO_ADDRESS,
                minter: ZERO_ADDRESS,
                burner: ZERO_ADDRESS,
                manager: ZERO_ADDRESS,
                exchanger: ZERO_ADDRESS,
                deployerKey: vm.envUint("PRIVATE_KEY"),
                participant: 0
            });
        }

        return result;
    }

    // deploy the contracts on the local network for testing
    function deploymentsOnLocalNetwork() public returns (DeploymentResult memory) {
        admin = makeAddr("admin");
        pauser = makeAddr("pauser");
        minter = makeAddr("minter");
        burner = makeAddr("burner");
        manager = makeAddr("manager");
        exchanger = makeAddr("exchanger");
        upgrader = makeAddr("admin");

        // deploy the utility token using the OpenZeppelin Upgrades library
        // address proxy = Upgrades.deployUUPSProxy(
        //     "ERC20UpgradeableTokenV1.sol",
        //     abi.encodeCall(
        //         ERC20UpgradeableTokenV1.initialize, ("AMA coin", "AMA", admin, pauser, minter, burner, admin)
        //     )
        // );

        /// This is using the UnsafeUpgrades method to deploy the UUPS in test environment not in production. This can be run to get the test coverage.
        address implementation = address(new ERC20UpgradeableTokenV1());
        address proxy = UnsafeUpgrades.deployUUPSProxy(
            implementation,
            abi.encodeCall(
                ERC20UpgradeableTokenV1.initialize, ("AMA coin", "AMA", admin, pauser, minter, burner, upgrader)
            )
        );

        utilityToken = ERC20UpgradeableTokenV1(proxy);

        // deploy the gov token
        govToken = new GovToken("Governance Token", "GOV", admin, minter, burner, exchanger);

        // deploy the voting power exchange
        votingPowerExchange =
            new VotingPowerExchange(address(govToken), address(utilityToken), admin, manager, exchanger);

        vm.startPrank(admin);
        // give exchange the minter role of govToken
        govToken.grantRole(govToken.MINTER_ROLE(), address(votingPowerExchange));
        // give exchange the burner role of utilityToken
        utilityToken.grantRole(utilityToken.BURNER_ROLE(), address(votingPowerExchange));
        // give exchange the voting power exchange role of govToken
        govToken.grantRole(govToken.VOTING_POWER_EXCHANGE_ROLE(), address(votingPowerExchange));
        vm.stopPrank();

        return DeploymentResult({
            utilityToken: address(utilityToken),
            govToken: address(govToken),
            exchange: address(votingPowerExchange),
            admin: admin,
            pauser: pauser,
            minter: minter,
            burner: burner,
            manager: manager,
            exchanger: exchanger,
            deployerKey: DEFAULT_ANVIL_KEY,
            participant: DEFAULT_ANVIL_KEY2
        });
    }

    // deploy the contracts on the base sepolia network for testing
    function deploymentsOnBaseSepolia() public returns (DeploymentResult memory) {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY_DEPLOYER"));
        uint256 privateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        // testnet we set all of the roles as deployer
        admin = deployer;
        pauser = deployer;
        minter = deployer;
        burner = deployer;
        manager = deployer;
        exchanger = deployer;
        upgrader = deployer;
        defender = vm.envAddress("OPENZEPPELIN_DEFENDER_ADDR");

        vm.startBroadcast(privateKey);
        // deploy the utility token using the OpenZeppelin Upgrades library
        address proxy = Upgrades.deployUUPSProxy(
            "ERC20UpgradeableTokenV1.sol",
            abi.encodeCall(
                ERC20UpgradeableTokenV1.initialize, ("AMA coin", "AMA", admin, pauser, minter, burner, upgrader)
            )
        );

        utilityToken = ERC20UpgradeableTokenV1(proxy);

        // deploy the gov token
        govToken = new GovToken("Governance Token", "GOV", admin, minter, burner, exchanger);

        // deploy the voting power exchange
        votingPowerExchange =
            new VotingPowerExchange(address(govToken), address(utilityToken), admin, manager, exchanger);

        // give exchange the minter role of govToken
        govToken.grantRole(govToken.MINTER_ROLE(), address(votingPowerExchange));
        // give exchange the burner role of utilityToken
        utilityToken.grantRole(utilityToken.BURNER_ROLE(), address(votingPowerExchange));
        // give exchange the voting power exchange role of govToken
        govToken.grantRole(govToken.VOTING_POWER_EXCHANGE_ROLE(), address(votingPowerExchange));

        // give exchange the minter role of govToken
        govToken.grantRole(govToken.MINTER_ROLE(), address(votingPowerExchange));
        // give exchange the burner role of utilityToken
        utilityToken.grantRole(utilityToken.BURNER_ROLE(), address(votingPowerExchange));
        // give defender the exchanger role
        votingPowerExchange.grantRole(votingPowerExchange.EXCHANGER_ROLE(), defender);

        // give exchanger some utility token
        utilityToken.mint(exchanger, 10_000 * 1e18);
        // exchanger should approve the votingPowerExchange to spend the utility token
        // here exchanger is deployer so we do this directly
        // change this method when exchanger is not deployer
        utilityToken.approve(address(votingPowerExchange), 10_000 * 1e18);
        vm.stopBroadcast();

        return DeploymentResult({
            utilityToken: address(utilityToken),
            govToken: address(govToken),
            exchange: address(votingPowerExchange),
            admin: admin,
            pauser: pauser,
            minter: minter,
            burner: burner,
            manager: manager,
            exchanger: exchanger,
            deployerKey: uint256(0), // this is for outputing the type
            participant: uint256(0) // this is for outputing the type
        });
    }
}
