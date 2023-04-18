// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/utils/cryptography/ECDSA.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ITask.sol";
import "./Registration.sol";

contract Task is ITask, OwnableUpgradeable {
    using ECDSA for bytes32;

    mapping (bytes32 => Task) public tasks;

    uint64 public RESPONSE_WINDOW = 100;
    uint64 CHALLENGE_WINDOW = 100;

    mapping (bytes32 => mapping (uint256 => mapping(address => bool))) public squaresData;

    Registration public registry;

    constructor (Registration _registry) {
        registry = _registry;
    }

    function postTask(
        uint128 number,
        uint64 blockNumber
    ) public {
        bytes32 taskId = _getTaskId(number, blockNumber);
        tasks[taskId] = Task(number, blockNumber);
    }

    function postTasks(
        uint128[] calldata numbers,
        uint64[] calldata blockNumbers
    ) external {
        require(numbers.length == blockNumbers.length, "Task: invalid input");
        for (uint256 i = 0; i < numbers.length; i++) {
            postTask(numbers[i], blockNumbers[i]);
        }
    }

    function submitTask(
        bytes32 _taskId,
        bytes calldata _responseData,
        bytes32[] calldata _r,
        bytes32[] calldata _s,
        uint8[] calldata _v
    ) external onlyOwner returns (bool) {
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

            resHash = keccak256(abi.encodePacked(operator, response));
            signer = _verifySignature(resHash, _r[i], _s[i], _v[i]);

            if (true) {
                squaresData[_taskId][response][operator] = true;
            } else {
                emit InvalidSignature(signer, _taskId, resHash);

                return false;
            }
        }

        return true;
    }

    function isRegistered(
        address _operator,
        bytes32 _taskId
    ) public view returns (bool) {
        return registry.checkOperatorStatus(_operator, _getBlockAtResponseWindowEnd(_taskId));
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

    // INTERNAL FUNCTIONS

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
}
