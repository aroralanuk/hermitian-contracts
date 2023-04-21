// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ECDSA} from "@openzeppelin/utils/cryptography/ECDSA.sol";
import {EnumerableSet} from "@openzeppelin/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {ITask} from "./interfaces/ITask.sol";
import {Registration} from "./Registration.sol";
import {DisputeResolution} from "./DisputeResolution.sol";

contract Task is ITask, Ownable {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping (bytes32 => Task) public tasks;

    uint64 public RESPONSE_WINDOW = 100;
    uint64 CHALLENGE_WINDOW = 100;

    uint64 internal nextChallengeWindowEnd = 0;

    uint256 public tasksRemaining = 0;

    mapping (bytes32 => mapping (address => uint256)) public squaresData;
    mapping (bytes32 => EnumerableSet.UintSet) potentialSquares;

    Registration public registry;
    DisputeResolution public dr;

    modifier inResponseWindow(bytes32 _taskId) {
        uint64 blockAtResponseWindowEnd = _getBlockAtResponseWindowEnd(_taskId);
        require(
            block.number <= blockAtResponseWindowEnd,
            "Task: response window is closed"
        );
        _;
    }

    modifier onlyDisputeResolution() {
        require(
            msg.sender == address(dr),
            "Task: only dispute resolution contract can call this function"
        );
        _;
    }


    modifier isChallengeOver(bytes32 _taskId) {
        uint64 blockAtChallengeWindowEnd = _getBlockAtChallengeWindowEnd(_taskId);
        require(
            block.number > blockAtChallengeWindowEnd,
            "Task: challenge is not over"
        );
        _;
    }

    constructor () {
        nextChallengeWindowEnd = uint64(block.number);
    }

    function setRegistry(Registration _registry) external onlyOwner {
        registry = _registry;
    }

    function setDisputeResolution(DisputeResolution _disputeResolution) external onlyOwner {
        dr = _disputeResolution;
    }


    function postTasks(
        uint128[] calldata numbers,
        uint64[] calldata blockNumbers
    ) external override {
        require(numbers.length == blockNumbers.length, "Task: invalid input");

        bytes32 _taskId;
        for (uint256 i = 0; i < numbers.length; i++) {
            _postTask(numbers[i], blockNumbers[i]);
            _taskId = _getTaskId(numbers[i], blockNumbers[i]);
            if (_getBlockAtChallengeWindowEnd(_taskId) > nextChallengeWindowEnd) {
                nextChallengeWindowEnd = _getBlockAtChallengeWindowEnd(_taskId);
            }
        }
        tasksRemaining += numbers.length;
    }


    function submitTask(
        bytes32 _taskId,
        bytes calldata _responseData,
        bytes32[] calldata _r,
        bytes32[] calldata _s,
        uint8[] calldata _v
    ) external onlyOwner inResponseWindow(_taskId) returns (bool) {
        require(
            _r.length == _s.length && _r.length == _v.length,
            "Invalid signature component lengths"
        );

        uint256 numResponses = _responseData.length / 64;
        require(
            _r.length == numResponses,
            "Mismatch between responseData and signature components"
        );

        address operator;
        uint256 response;
        bytes32 resHash;
        address signer;

        for (uint64 i = 0; i < numResponses; i++) {
            (operator, response) = abi.decode(
                _responseData[64 * i:64 * (i + 1)],
                (address, uint256)
            );

            if (!isActive(operator)) {
                emit OperatorNotActive(operator, _taskId);
            }

            resHash = keccak256(abi.encodePacked(operator, response));
            signer = _verifySignature(resHash, _r[i], _s[i], _v[i]);


            if (signer == operator) {
                squaresData[_taskId][operator] = response;
                potentialSquares[_taskId].add(response);
            } else {
                emit InvalidSignature(signer, _taskId, resHash);
            }
        }

        return true;
    }

    function isActive(
        address _operator
    ) public view returns (bool) {
        return registry.checkActiveStatus(_operator);
    }

    function isRegistered(
        address _operator,
        bytes32 _taskId
    ) public view returns (bool) {
        return registry.checkOperatorStatus(_operator, _getBlockAtResponseWindowEnd(_taskId));
    }


    function completeTask(
        bytes32 _taskId
    ) external isChallengeOver(_taskId) returns (uint256 actualSquare) {
        require(potentialSquares[_taskId].length() > 0, "Task: no valid responses");
        require(tasks[_taskId].square == 0, "Task: task already completed");

        uint256 randomIndex = _getPseudoRandom() % potentialSquares[_taskId].length();

        actualSquare = potentialSquares[_taskId].at(randomIndex);

        tasks[_taskId].square = actualSquare;
        tasksRemaining -= 1;
    }

    function inChallengeWindow(bytes32 _taskId) external view returns (bool) {
        uint64 blockAtChallengeWindowEnd = _getBlockAtChallengeWindowEnd(_taskId);
        uint64 blockAtResponseWindowEnd = _getBlockAtResponseWindowEnd(_taskId);

        return
            blockAtResponseWindowEnd <= block.number &&
            block.number <= blockAtChallengeWindowEnd;

    }

    function nextChallengeEnd(uint64 minimum) external view returns (uint64) {
        return minimum > nextChallengeWindowEnd ? minimum : nextChallengeWindowEnd;
    }

    function removeInvalidSquare(
        bytes32 _taskId,
        uint256 _square
    ) external onlyDisputeResolution {

        potentialSquares[_taskId].remove(_square);
    }

    function getTask(
        bytes32 _taskId
    ) external override view returns (Task memory) {
        return tasks[_taskId];
    }

    function getSquaresData(
        bytes32 _taskId,
        address _operator
    ) external view returns (uint256) {
        return squaresData[_taskId][_operator];
    }

    function _getTaskId(
        uint128 number,
        uint256 blockNumber
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(number, blockNumber));
    }


    // INTERNAL FUNCTIONS


    function _postTask(
        uint128 number,
        uint64 blockNumber
    ) internal {
        bytes32 taskId = _getTaskId(number, blockNumber);
        tasks[taskId] = Task(number, blockNumber, 0);

        emit TaskPosted(taskId, number, blockNumber);
    }

    function _verifySignature(
        bytes32 _hash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal pure returns (address signer) {
        bytes32 messageHash = _hash.toEthSignedMessageHash();
        signer = messageHash.recover(v, r, s);
    }

    function _getBlockAtTaskCreated(
        bytes32 _taskId
    ) internal view returns (uint64) {
        return tasks[_taskId].blockNumber;
    }

    function _getBlockAtResponseWindowEnd(
        bytes32 _taskId
    ) internal view returns (uint64) {
        return _getBlockAtTaskCreated(_taskId) + RESPONSE_WINDOW;
    }

    function _getBlockAtChallengeWindowEnd(
        bytes32 _taskId
    ) internal view returns (uint64) {
        return _getBlockAtResponseWindowEnd(_taskId) + CHALLENGE_WINDOW;
    }

    function _getPseudoRandom() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp)));
    }
}
