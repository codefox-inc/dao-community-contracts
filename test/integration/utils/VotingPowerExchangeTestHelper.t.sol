// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {DeployContracts, DeploymentResult} from "script/DeployContracts.s.sol";
import {Test, console} from "forge-std/Test.sol";

import {VotingPowerExchange} from "src/VotingPowerExchange.sol";

contract VotingPowerExchangeTestHelper is Test {
    bytes32 private constant _EXCHANGE_TYPEHASH =
        keccak256("Exchange(address sender,uint256 amount,bytes32 nonce,uint256 expiration)");

    function generateSignatureFromPrivateKey(uint256 privateKey, uint256 amount, uint256 nonce, uint256 expiration)
        public
        view
        returns (bytes memory)
    {
        address sender = address(uint160(privateKey));
        bytes32 structHash = keccak256(abi.encode(_EXCHANGE_TYPEHASH, sender, amount, nonce, expiration));

        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("VotingPowerExchange")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);

        return abi.encodePacked(r, s, v);
    }
}
