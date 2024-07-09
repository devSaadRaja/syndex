// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseAggregator.sol";

contract AggregatorIssuedSynths is BaseAggregator {
    bytes32 public constant CONTRACT_NAME = "AggregatorIssuedSynths";

    constructor(AddressResolver _resolver) BaseAggregator(_resolver) {}

    function getRoundData(
        uint80
    ) public view override returns (uint80, int256, uint256, uint256, uint80) {
        uint totalIssuedSynths = IIssuer(
            resolver.requireAndGetAddress("Issuer", "aggregate debt info")
        ).totalIssuedSynths("cfUSD", true);

        uint dataTimestamp = block.timestamp;

        if (overrideTimestamp != 0) {
            dataTimestamp = overrideTimestamp;
        }

        return (1, int256(totalIssuedSynths), dataTimestamp, dataTimestamp, 1);
    }
}
