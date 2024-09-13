// SPDX-License-Identifier: MIT
// TODO: WIP

pragma solidity 0.8.24;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    // minDelay is the minimum time allowed before executing a transaction
    // proposers is an array of addresses that are allowed to propose
    // executors is an array of addresses that are allowed to execute
    // TODO: we need to remove the admin from the contract eventually
    // need to grant the role of minter of govToken to the timelock contract
    // grant zero address to the timelock contract if you want to allow anyone to execute
    // grant the role of proposer to the daoGovernor contract

    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
