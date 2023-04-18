// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract Registration {
    struct Operator {
        uint64 fromBlockNumber;
        uint64 toBlockNumber;
        uint64 index;
    }

    mapping (address => Operator) public operatorDetails;

    address[] public operators;

    function registerOperator(
        address _operator
    ) external {
        // TODO: if operator is already registered
        require(operatorDetails[_operator].fromBlockNumber == 0, "Operator already registered");
        operatorDetails[_operator] = Operator({
            fromBlockNumber: uint64(block.number),
            toBlockNumber: 0,
            index: uint64(operators.length)
        });
        operators.push(_operator);
    }

    function checkOperatorStatus(
        address operator,
        uint64 blockNumber
    ) external view returns (bool) {
        Operator memory op = operatorDetails[operator];
        if (op.fromBlockNumber == 0) {
            return false;
        }
        if (op.toBlockNumber == 0) {
            return true;
        }
        return op.fromBlockNumber <= blockNumber && blockNumber <= op.toBlockNumber;
    }
}
