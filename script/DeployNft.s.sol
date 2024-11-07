// DeployNft.s.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {AmbassadorNft} from "src/AmbassadorNft.sol";

contract DeployNft is Script {
    function run() public {
        address defender = vm.envAddress("TESTNET_OPENZEPPELIN_DEFENDER_ADDR");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        address deployer = vm.addr(deployerPrivateKey);
        address admin = deployer;
        address minter = defender;
        address burner = defender;
        address uriSetter = defender;

        vm.startBroadcast(deployerPrivateKey);

        AmbassadorNft nft = new AmbassadorNft(admin, minter, burner, uriSetter);

        console.log("Deployer:", deployer);
        console.log("AmbassadorNft deployed at:", address(nft));

        vm.stopBroadcast();
    }
}
