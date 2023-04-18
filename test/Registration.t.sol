// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "src/Registration.sol";
import "./BaseTest.sol";

contract RegistrationTest is BaseTest {
    Registration registration;

    function setUp() public override {
        super.setUp();
        registration = new Registration();
    }

    function testRegisterOperator() public {
        registration.registerOperator(alice);

        (uint64 from, uint64 to, uint64 index) = registration.operatorDetails(alice);
        assertEq(uint64(block.number), from);
        assertEq(0, to);
        assertEq(0, index);
    }

    function testCheckOperatorStatus() public {
        // go forward 10 blocks
        vm.roll(block.number + 10);
        registration.registerOperator(alice);

        bool statusBeforeRegistration = registration.checkOperatorStatus(alice, uint64(block.number - 1));
        bool statusAfterRegistration = registration.checkOperatorStatus(alice, uint64(block.number));

        assertFalse(statusBeforeRegistration);
        assertTrue(statusAfterRegistration);
    }

    // test if anyone can register

    // test if the registered operator can deregister

    // test if operator can only deregister after challenge window if they didn't deregister by the end of the response window

    // test to check if status of operator at a specific block
}
