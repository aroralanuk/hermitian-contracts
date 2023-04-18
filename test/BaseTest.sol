
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

abstract contract BaseTest is Test {


    address constant alice = address(uint160(uint256(keccak256("alice"))));
    address constant bob = address(uint160(uint256(keccak256("bob"))));
    address constant charlie = address(uint160(uint256(keccak256("charlie"))));
    address constant devin = address(uint160(uint256(keccak256("devin"))));
    address constant ellie = address(uint160(uint256(keccak256("ellie"))));

    function setUp() public virtual {
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(charlie, "charlie");
        vm.label(devin, "devin");
        vm.label(ellie, "ellie");
    }
}
