// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface ITask {
    event InvalidSignature(address signer, bytes32 taskId, bytes32 hash);

    struct Task {
        uint128 number;
        uint64 blockNumber;
    }
}
