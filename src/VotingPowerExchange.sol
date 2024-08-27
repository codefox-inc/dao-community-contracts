// SPDX-License-Identifier: BUSL-1.1
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VotingPowerExchange {
    IERC20 public immutable govToken;
    IERC20 public immutable votingPowerToken;

    constructor(IERC20 _govToken, IERC20 _votingPowerToken) {
        govToken = _govToken;
        votingPowerToken = _votingPowerToken;
    }

    function exchange(uint256 amount) external {
        // govToken.transferFrom(msg.sender, address(this), amount);
        // votingPowerToken.transfer(msg.sender, amount);
    }
}
