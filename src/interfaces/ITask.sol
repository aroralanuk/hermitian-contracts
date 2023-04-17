// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface ITask {
    struct Task {
        uint128 number;
        uint128 blockNumber;
    }

    struct Responses {
        address[] operators;
        uint256[] responses;
    }

    struct SquareData {
        mapping (address => uint256) responses;
        // set of possible responses
    }

}
