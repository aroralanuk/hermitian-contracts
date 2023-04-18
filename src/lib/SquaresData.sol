library Squares {
    struct SquareData {
        mapping (address => address) responses;
        uint32 numResponses;
    }

    function add(
        SquareData storage self,
        address operator
    ) internal {
        address SENTINEL = address(0x1);
        require(operator != address(0) && operator != SENTINEL, "Invalid operator address");
        require(self.responses[operator] == address(0), "Operator already responded");

        self.responses[operator] = self.responses[SENTINEL];
        self.responses[SENTINEL] = operator;
        self.numResponses++;
    }

    // TODO: how to do without prevOperator?
    function remove(
        SquareData storage self,
        address prevOperator,
        address operator
    ) internal {
        address SENTINEL = address(0x1);
        require(operator != address(0) && operator != SENTINEL, "Invalid operator address");
        require(self.responses[prevOperator] == operator, "Operator not found");

        self.responses[prevOperator] = self.responses[operator];
        self.responses[operator] = address(0);
        self.numResponses--;
    }
}
