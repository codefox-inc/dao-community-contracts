// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {console, Script} from "forge-std/Script.sol";
import {ERC20UpgradeableTokenV1} from "src/ERC20UpgradeableTokenV1.sol";
import {VotingPowerExchange} from "src/VotingPowerExchange.sol";
import {GovToken} from "src/GovToken.sol";

contract GrantRolesContract is Script {
    // contracts instances
    GovToken public govToken;
    ERC20UpgradeableTokenV1 public utilityToken;
    VotingPowerExchange public votingPowerExchange;

    // admin roles
    address public constant ZERO_ADDRESS = address(0);
    address public targetAddress = vm.envAddress("TARGET_ADDRESS");
    address public utilityTokenAddress = vm.envAddress("UTILITY_TOKEN_ADDRESS");
    address public govTokenAddress = vm.envAddress("GOV_TOKEN_ADDRESS");
    address public exchangeAddress = vm.envAddress("EXCHANGE_ADDRESS");

    function run() public {
        // local netwrok
        if (block.chainid == 31337) {
            console.log("Granting roles on the local testnet");
        } else if (block.chainid == 84532) {
            console.log("Granting roles on the base testnet");

            grantRolesToTargetAddress(targetAddress, utilityTokenAddress, govTokenAddress, exchangeAddress);
        } else if (block.chainid == 8453) {
            console.log("Granting roles on the base mainnet");
        }
    }

    // deploy the contracts on the base sepolia network for testing
    function grantRolesToTargetAddress(
        address targetAddr,
        address utilityTokenAddr,
        address govTokenAddr,
        address exchangeAddr
    ) public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");

        //// start calling onchain functions ////
        vm.startBroadcast(privateKey);

        utilityToken = ERC20UpgradeableTokenV1(utilityTokenAddr);
        govToken = GovToken(govTokenAddr);
        votingPowerExchange = VotingPowerExchange(exchangeAddr);

        // give the roles of utility token
        // give the admin role to the target address
        utilityToken.grantRole(utilityToken.DEFAULT_ADMIN_ROLE(), targetAddr);
        // give the pauser role to the target address
        utilityToken.grantRole(utilityToken.PAUSER_ROLE(), targetAddr);
        // give the minter role to the target address
        utilityToken.grantRole(utilityToken.MINTER_ROLE(), targetAddr);
        // give the burner role to the target address
        utilityToken.grantRole(utilityToken.BURNER_ROLE(), targetAddr);
        // give the upgrader role to the target address
        utilityToken.grantRole(utilityToken.UPGRADER_ROLE(), targetAddr);

        // give the roles of gov token
        // give the admin role to the target address
        govToken.grantRole(govToken.DEFAULT_ADMIN_ROLE(), targetAddr);
        // give the minter role of govToken
        govToken.grantRole(govToken.MINTER_ROLE(), targetAddr);
        // give the burner role of utilityToken
        govToken.grantRole(govToken.BURNER_ROLE(), targetAddr);
        // give the voting power exchange role of govToken
        govToken.grantRole(govToken.VOTING_POWER_EXCHANGE_ROLE(), targetAddr);

        // give the roles of voting power exchange
        // give the admin role
        votingPowerExchange.grantRole(votingPowerExchange.DEFAULT_ADMIN_ROLE(), targetAddr);
        // give the exchanger role
        votingPowerExchange.grantRole(votingPowerExchange.EXCHANGER_ROLE(), targetAddr);
        // give the manager role
        votingPowerExchange.grantRole(votingPowerExchange.MANAGER_ROLE(), targetAddr);

        vm.stopBroadcast();
    }
}
