// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/VotingPowerExchange.sol";

contract TestBaseSepolia is Test {
    VotingPowerExchange public votingPowerExchange;
    address public constant DEPLOYED_CONTRACT_ADDRESS = 0x8016b49aFd80A62191296e630174C2352129349A; // the actual deployed address on Base Sepolia

    function setUp() public {
        // Get the instance of the deployed contract
        votingPowerExchange = VotingPowerExchange(DEPLOYED_CONTRACT_ADDRESS);
    }

    function testExchangeOnChain01() public {
        // Set up the state required for the test (if needed)
        // For example, simulate a user address
        address exchanger = 0x5aB0ffF1a51ee78F67247ac0B90C8c1f1f54c37F;
        vm.startPrank(exchanger);

        // Call the exchange function
        votingPowerExchange.exchange(
            0x588A7E62547CB573084C8608486d60E567c573d0,
            2000000000000000000,
            bytes32(0x45a6cd4929f515c60c82473f16bc1fad9e8b95c04e18e76c7dfc9a6548cb5b60),
            1727871292,
            hex"bc9dd8b708b7ad5dd8dd68e422cd6b44ac6f6aebeabad4c1e52a1942e267c3af36e5d9aafff7fd8657444991613de3276a308bc858cc8e91e28f58142ff34faa1b"
        ); // Assuming exchange accepts a uint256 parameter

        // Make assertions to verify the results
        // assertEq(votingPowerExchange.balanceOf(user), 100, "Exchange failed");

        vm.stopPrank();
    }
}
