// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {Task} from "src/Task.sol";
import {Registration} from "src/Registration.sol";
import {DisputeResolution} from "src/DisputeResolution.sol";


contract HermitianScript is Script {
    Task task;
    Registration registry;
    DisputeResolution dr;
    function setUp() public {}

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        // task = new Task();
        // registry = new Registration(task);
        // dr = new DisputeResolution(task, registry);

        // task.setDisputeResolution(dr);
        // task.setRegistry(registry);

        vm.stopBroadcast();
    }
}
