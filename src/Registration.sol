// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Task} from "./Task.sol";
import {DisputeResolution} from "./DisputeResolution.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

/// @title Registration contract
/// @notice This contract is used to register and deregister operators
contract Registration is Ownable {
    event DeregistrationSelf(address operator, uint64 blockNumber);
    event DeregistrationOnChallenge(address operator, uint64 blockNumber);

    /// @dev Represents if the operator can actively participate in the task
    enum Status {
        SUBSCRIBED,
        UNSUBSCRIBED
    }

    struct Operator {
        uint64 fromBlockNumber;
        uint64 toBlockNumber;
        Status status;
    }

    /// @notice each operator can have multiple windows of registration
    mapping (address => Operator[]) public operatorDetails;

    address[] public operators;

    Task task;
    DisputeResolution dr;

    modifier onlyDisputeResolution() {
        require(
            msg.sender == address(dr),
            "Task: only dispute resolution contract can call this function"
        );
        _;
    }

    constructor(Task _task) {
        task = _task;
    }

    function setDisputeResolution(DisputeResolution _dr) external onlyOwner {
        dr = _dr;
    }

    function registerSelf(
    ) external returns (bool) {
        require(!checkOperatorStatus(msg.sender, uint64(block.number)), "Operator currently registered");

        operators.push(msg.sender);

        Operator memory newEntry = Operator({
            fromBlockNumber: uint64(block.number),
            toBlockNumber: 0,
            status: Status.SUBSCRIBED
        });
        operatorDetails[msg.sender].push(newEntry);

        return true;
    }

    function deregisterSelf() external returns (bool) {
        address _operator = msg.sender;
        uint256 len = operatorDetails[_operator].length;
        if (len == 0) return false;

        operatorDetails[_operator][len - 1].status = Status.UNSUBSCRIBED;
        operatorDetails[_operator][len - 1].toBlockNumber = task.nextChallengeEnd(uint64(block.number));

        emit DeregistrationSelf(_operator, task.nextChallengeEnd(uint64(block.number)));

        return true;
    }

    function deregisterOperator(address _operator) external onlyDisputeResolution returns (bool){
        uint256 len = operatorDetails[_operator].length;
        if (len == 0) return false;

        operatorDetails[_operator][len - 1].status = Status.UNSUBSCRIBED;
        operatorDetails[_operator][len - 1].toBlockNumber = uint64(block.number);

        emit DeregistrationOnChallenge(_operator, uint64(block.number));

        return true;
    }

    function checkActiveStatus(address _operator) external view returns (bool) {
        return operatorDetails[_operator].length > 0 &&
            operatorDetails[_operator][operatorDetails[_operator].length - 1].status == Status.SUBSCRIBED;
    }

    function checkOperatorStatus(
        address _operator,
        uint64 _blockNumber
    ) public view returns (bool) {
        uint256 len = operatorDetails[_operator].length;
        if (len == 0) return false;
        Operator memory op = operatorDetails[_operator][len - 1];

        while (len - 1 > 0 && op.fromBlockNumber > _blockNumber) {
            len--;
            op = operatorDetails[_operator][len - 1];
        }

        return op.fromBlockNumber <= _blockNumber  &&
            (
                op.status == Status.SUBSCRIBED ||
                (op.fromBlockNumber <= _blockNumber && _blockNumber <= op.toBlockNumber)
            );
    }
}
