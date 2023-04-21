// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITask} from "./interfaces/ITask.sol";
import {Task} from "./Task.sol";
import {Registration} from "./Registration.sol";

contract DisputeResolution {
    event OperatorResponseValid(bytes32 taskId, address operator, uint256 squareResponse);
    event OperatorResponseInvalid(bytes32 taskId, address operator, uint256 squareResponse);

    Task task;
    Registration registry;

    mapping (bytes32 => mapping (address => bool)) challenged;

    modifier inChallengeWindow(bytes32 _taskId) {
        require(task.inChallengeWindow(_taskId), "Task: not in challenge window");
        _;
    }

    constructor(Task _task, Registration _registry) {
        task = _task;
        registry = _registry;
    }

    function challengeResponse(
        bytes32 _taskId,
        address _operator
    ) external inChallengeWindow(_taskId) returns (bool) {
        // // check if operator is registered
        require(task.isRegistered(_operator, _taskId), "Task: operator is not registered");
        require(!challenged[_taskId][_operator], "Task: operator has already been challenged");

        uint256 operatorResponse = task.getSquaresData(_taskId,_operator);

        // works for when operator didn't respond because response is 0
        ITask.Task memory taskStruct = task.getTask(_taskId);
        bool validResponse = _checkSquare(taskStruct.number, operatorResponse);

        if (validResponse) {
            emit OperatorResponseValid(_taskId, _operator, operatorResponse);
        } else {
            registry.deregisterOperator(_operator);
            task.removeInvalidSquare(_taskId,operatorResponse);

            emit OperatorResponseInvalid(_taskId, _operator, operatorResponse);
        }

        challenged[_taskId][_operator] = true;
        return !validResponse;
    }


    function _checkSquare(
        uint128 number,
        uint256 allegedSquare
    ) internal pure returns (bool) {
        uint256 square = allegedSquare * allegedSquare;
        return square == number;
    }
}
