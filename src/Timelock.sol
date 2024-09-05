// SPDX-License-Identifier: MIT
// TODO: WIP

pragma solidity 0.8.24;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    // minDelay is the minimum time allowed before executing a transaction
    // proposers is an array of addresses that are allowed to propose
    // executors is an array of addresses that are allowed to execute

    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
