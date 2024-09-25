// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/VotingPowerExchange.sol";
import "src/ERC20UpgradeableTokenV1.sol";

contract TestBaseSepolia is Test {
    VotingPowerExchange public votingPowerExchange;
    address public constant DEPLOYED_CONTRACT_ADDRESS = 0x8016b49aFd80A62191296e630174C2352129349A; // the actual deployed address on Base Sepolia

    ERC20UpgradeableTokenV1 public utilityToken;

    function setUp() public {
        // Get the instance of the deployed contract
        votingPowerExchange = VotingPowerExchange(DEPLOYED_CONTRACT_ADDRESS);
        utilityToken = ERC20UpgradeableTokenV1(0x091dFFe4A5625420a998589E451A15c753073Cda);
    }

    function testExchangeOnChain01() public {
        // Set up the state required for the test (if needed)
        // For example, simulate a user address
        uint256 balanceBefore = utilityToken.balanceOf(0x588A7E62547CB573084C8608486d60E567c573d0);

        address sender = 0x588A7E62547CB573084C8608486d60E567c573d0;
        uint256 amount = 2000000000000000000;
        bytes32 nonce = bytes32(0x45a6cd4929f515c60c82473f16bc1fad9e8b95c04e18e76c7dfc9a6548cb5b60);
        uint256 timestamp = 1727871292;
        bytes memory signature =
            hex"bc9dd8b708b7ad5dd8dd68e422cd6b44ac6f6aebeabad4c1e52a1942e267c3af36e5d9aafff7fd8657444991613de3276a308bc858cc8e91e28f58142ff34faa1b";

        address exchanger = 0x5aB0ffF1a51ee78F67247ac0B90C8c1f1f54c37F;
        vm.startPrank(exchanger);

        // Call the exchange function
        votingPowerExchange.exchange(sender, amount, nonce, timestamp, signature);
        vm.stopPrank();

        // Make assertions to verify the results
        assertEq(
            utilityToken.balanceOf(0x588A7E62547CB573084C8608486d60E567c573d0),
            balanceBefore - 2000000000000000000,
            "Exchange failed"
        );
    }
}
