// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICircuitBreaker {
    // Views
    function isInvalid(
        address oracleAddress,
        uint value
    ) external view returns (bool);

    function priceDeviationThresholdFactor() external view returns (uint);

    function isDeviationAboveThreshold(
        uint base,
        uint comparison
    ) external view returns (bool);

    function lastValue(address oracleAddress) external view returns (uint);

    function circuitBroken(address oracleAddress) external view returns (bool);

    // Mutative functions
    function resetLastValue(
        address[] calldata oracleAddresses,
        uint[] calldata values
    ) external;

    function probeCircuitBreaker(
        address oracleAddress,
        uint value
    ) external returns (bool);
}
