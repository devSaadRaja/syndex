// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseAggregator.sol";

contract AggregatorETH is BaseAggregator {
    bytes32 public constant CONTRACT_NAME = "AggregatorETH";

    uint256 price = 1 * 10 ** 18;

    constructor(AddressResolver _resolver) BaseAggregator(_resolver) {}

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function getRoundData(
        uint80
    ) public view override returns (uint80, int256, uint256, uint256, uint80) {
        uint dataTimestamp = block.timestamp;

        if (overrideTimestamp != 0) {
            dataTimestamp = overrideTimestamp;
        }

        return (1, int256(price), dataTimestamp, dataTimestamp, 1);
    }
}
