// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {AmbassadorNft} from "src/AmbassadorNft.sol";
import {ERC20UpgradeableTokenV1} from "src/ERC20UpgradeableTokenV1.sol";
import {GovToken} from "src/GovToken.sol";
import {VotingPowerExchange} from "src/VotingPowerExchange.sol";

contract VotingPwoerExchangeTest is Test {
    // instances
    GovToken govToken;
    ERC20UpgradeableTokenV1 utilityToken;
    VotingPowerExchange votingPowerExchange;

    function setUp() public {}
}
