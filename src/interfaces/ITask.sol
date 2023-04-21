// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface ITask {
    event InvalidSignature(address signer, bytes32 taskId, bytes32 hash);
    event TaskPosted(bytes32 taskId, uint128 number, uint64 blockNumber);
    event OperatorNotActive(address operator, bytes32 taskId);

    struct Task {
        uint128 number;
        uint64 blockNumber;
        uint256 square;
    }

    function postTasks(
        uint128[] calldata numbers,
        uint64[] calldata blockNumbers
    ) external;

    function getTask(
        bytes32 _taskId
    ) external view returns (Task memory);

    function tasksRemaining() external view returns (uint256);
}
