// DeployNft.s.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {console, Script} from "forge-std/Script.sol";
import {AmbassadorNft} from "src/AmbassadorNft.sol";

contract DeployNft is Script {
    function setUp() public {
        vm.startBroadcast();
    }
}
