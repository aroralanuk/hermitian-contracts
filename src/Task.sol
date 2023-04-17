// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ITask.sol";

contract Task is ITask {
    mapping (bytes32 => Task) public tasks;

    uint32 public RESPONSE_WINDOW = 100;
    uint32 CHALLENGE_WINDOW = 100;

    function postTask(
        uint128 number,
        uint128 blockNumber
    ) public {
        bytes32 taskId = _getTaskId(number, blockNumber);
        tasks[taskId] = Task(number, blockNumber);
    }

    function postTasks(
        uint128[] calldata numbers,
        uint128[] calldata blockNumbers
    ) external {
        require(numbers.length == blockNumbers.length, "Task: invalid input");
        for (uint256 i = 0; i < numbers.length; i++) {
            postTask(numbers[i], blockNumbers[i]);
        }
    }

    function submitTask(
        bytes calldata _responseAggregate,
        bytes32[] calldata _rs,
        bytes32[] calldata _ss,
        uint8[] calldata _vs
    ) external {
        Responses memory ra;

        (ra.operators, ra.responses) = abi.decode(
            _responseAggregate,
            (address[], uint256[])
        );

        require(ra.operators.length == ra.responses.length, "Task: invalid input");
        require(_rs.length == _ss.length, "Task: invalid input");
        require(ra.operators.length == _rs.length, "Task: invalid input");

        // loop through
        // check if operator is registered

        // verify ECDSA signatures

        // store into squareData

        //
    }

    function challengeResponse(
        bytes32 _taskId,
        address _operator,
        uint256 _response
    ) external {
        // check if challenge window is open

        // check if operator is registered

        // check if response is valid

        // check if response is already challenged

    }


    function completeTask(
        bytes32 _taskId
    ) external {
        // check if response window is open

        // get the consensus response
    }

    function getSquare(
        bytes32 _taskId
    ) external view returns (uint256[] memory) {
        // TODO: implement
    }



    function _getTaskId(
        uint128 number,
        uint256 blockNumber
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(number, blockNumber));
    }
}
