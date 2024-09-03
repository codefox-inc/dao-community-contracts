// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {DeployContracts, DeploymentResult} from "script/DeployContracts.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {AmbassadorNft} from "src/AmbassadorNft.sol";
import {ERC20UpgradeableTokenV1} from "src/ERC20UpgradeableTokenV1.sol";
import {GovToken} from "src/GovToken.sol";
import {VotingPowerExchange} from "src/VotingPowerExchange.sol";

contract VotingPwoerExchangeTest is Test {
    // instances
    GovToken public govToken;
    ERC20UpgradeableTokenV1 public utilityToken;
    VotingPowerExchange public votingPowerExchange;
    DeployContracts public dc;

    // admin roles
    address admin;
    address pauser;
    address minter;
    address burner;
    address manager;
    address exchanger;

    // deploy scripts
    function setUp() public {
        dc = new DeployContracts();
        DeploymentResult memory tempResult = dc.run();

        utilityToken = ERC20UpgradeableTokenV1(tempResult.utilityToken);
        govToken = GovToken(tempResult.govToken);
        votingPowerExchange = VotingPowerExchange(tempResult.exchange);
    }

    function test() public pure {}
}
