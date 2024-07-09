// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseAggregator.sol";

import "../libraries/SafeDecimalMath.sol";

// aggregator which reports the data from the system itself
// useful for testing
contract AggregatorDebtRatio is BaseAggregator {
    using SafeDecimalMath for uint;

    bytes32 public constant CONTRACT_NAME = "AggregatorDebtRatio";

    constructor(AddressResolver _resolver) BaseAggregator(_resolver) {}

    function getRoundData(
        uint80
    ) public view override returns (uint80, int256, uint256, uint256, uint80) {
        uint totalIssuedSynths = IIssuer(
            resolver.requireAndGetAddress("Issuer", "aggregate debt info")
        ).totalIssuedSynths("cfUSD", true);
        uint totalDebtShares = ISynDexDebtShare(
            resolver.requireAndGetAddress(
                "SynDexDebtShare",
                "aggregate debt info"
            )
        ).totalSupply();

        uint result = totalDebtShares == 0
            ? 10 ** 27
            : totalIssuedSynths.decimalToPreciseDecimal().divideDecimalRound(
                totalDebtShares
            );

        uint dataTimestamp = block.timestamp;

        if (overrideTimestamp != 0) {
            dataTimestamp = overrideTimestamp;
        }

        return (1, int256(result), dataTimestamp, dataTimestamp, 1);
    }
}
