// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Task} from "src/Task.sol";
import {Registration} from "src/Registration.sol";
import {DisputeResolution} from "src/DisputeResolution.sol";
import "./BaseTest.sol";



contract MockTask is Task {
    function setNextChallengeWindow(uint64 _nextChallengeWindow) public {
        nextChallengeWindowEnd = _nextChallengeWindow;
    }
}

contract RegistrationTest is BaseTest {
    MockTask task;
    Registration registration;
    DisputeResolution dr;

    function setUp() public override {
        super.setUp();

        task = new MockTask();
        registration = new Registration(task);
        dr = new DisputeResolution(task, registration);

        registration.setDisputeResolution(dr);
        task.setRegistry(registration);

    }

    function testRegisterSelf() public {
        vm.roll(block.number + 10);
        vm.prank(alice);
        registration.registerSelf();

        (uint64 from, uint64 to, Registration.Status status) = registration.operatorDetails(alice, 0);
        assertEq(uint64(block.number), from);
        assertEq(0, to);
        assertTrue(status == Registration.Status.SUBSCRIBED);

        bool statusBeforeRegistration = registration.checkOperatorStatus(alice, uint64(block.number - 1));
        bool statusAfterRegistration = registration.checkOperatorStatus(alice, uint64(block.number));

        assertFalse(statusBeforeRegistration);
        assertTrue(statusAfterRegistration);
    }

    function testRegisterSelf_Fail_Duplicate() public {
        vm.startPrank(alice);
        registration.registerSelf();

        vm.expectRevert("Operator currently registered");
        registration.registerSelf();

        bool status = registration.checkOperatorStatus(alice, uint64(block.number));
        assertTrue(status);
    }

    function testDeregisterSelf() public {
        vm.startPrank(alice);
        registration.registerSelf();

        task.setNextChallengeWindow(uint64(block.number + 25));
        registration.deregisterSelf();

        (uint64 from, uint64 to, Registration.Status status) = registration.operatorDetails(alice, 0);
        assertEq(uint64(block.number), from);
        assertEq(uint64(block.number + 25), to);
        assertTrue(status == Registration.Status.UNSUBSCRIBED);
    }

    function testDeregisterSelf_Fail_NotRegistered() public {
        assertFalse(registration.deregisterSelf());
    }

    function testDeregister_Challenge() public {
        vm.prank(alice);
        registration.registerSelf();

        vm.roll(block.number + 10);
        vm.prank(address(dr));
        registration.deregisterOperator(alice);

        (uint64 from, uint64 to, Registration.Status status) = registration.operatorDetails(alice, 0);
        assertEq(uint64(block.number - 10), from);
        assertEq(uint64(block.number), to);
        assertTrue(status == Registration.Status.UNSUBSCRIBED);

    }

    function testDeregisterSelf_Fail_RegisterTooSoon() public {
        vm.startPrank(alice);
        registration.registerSelf();

        task.setNextChallengeWindow(uint64(block.number + 25));
        registration.deregisterSelf();

        vm.expectRevert("Operator currently registered");
        registration.registerSelf();
    }

    function testCheckOperatorStatus_PreviousRegistraion() public {
        vm.roll(block.number + 10);

        vm.startPrank(alice);
        registration.registerSelf();

        task.setNextChallengeWindow(uint64(block.number + 25));
        registration.deregisterSelf();

        vm.roll(block.number + 50);
        registration.registerSelf();


        bool currentStatus = registration.checkOperatorStatus(alice, uint64(block.number));
        bool betweenStatus = registration.checkOperatorStatus(alice, uint64(block.number - 10));
        bool beforeStatus = registration.checkOperatorStatus(alice, uint64(block.number - 30));
        bool evenBeforeStatus = registration.checkOperatorStatus(alice, uint64(block.number - 55));

        assertFalse(evenBeforeStatus);
        assertTrue(beforeStatus);
        assertFalse(betweenStatus);
        assertTrue(currentStatus);

        vm.stopPrank();
    }

    function testCheckOperatorStatus_RegAfterDispute() public {
        vm.roll(block.number + 10);

        vm.prank(alice);
        registration.registerSelf();

        vm.prank(address(dr));
        registration.deregisterOperator(alice);

        vm.roll(block.number + 2);
        vm.prank(alice);
        registration.registerSelf();


        bool currentStatus = registration.checkOperatorStatus(alice, uint64(block.number));
        bool betweenStatus = registration.checkOperatorStatus(alice, uint64(block.number - 1));
        bool beforeStatus = registration.checkOperatorStatus(alice, uint64(block.number - 2));

        assertTrue(beforeStatus);
        assertFalse(betweenStatus);
        assertTrue(currentStatus);

        vm.stopPrank();
    }
}
