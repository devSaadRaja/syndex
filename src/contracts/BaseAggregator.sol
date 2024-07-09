// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./AddressResolver.sol";
import "../interfaces/IDebtCache.sol";
import "../interfaces/ISynDexDebtShare.sol";

// aggregator which reports the data from the system itself
// useful for testing
abstract contract BaseAggregator is Ownable {
    AddressResolver public resolver;

    uint256 public overrideTimestamp;

    constructor(AddressResolver _resolver) Ownable(msg.sender) {
        resolver = _resolver;
    }

    function setOverrideTimestamp(uint timestamp) public onlyOwner {
        overrideTimestamp = timestamp;

        emit SetOverrideTimestamp(timestamp);
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return getRoundData(uint80(latestRound()));
    }

    function latestRound() public pure returns (uint256) {
        return 1;
    }

    function decimals() external pure returns (uint8) {
        return 0;
    }

    function getAnswer(uint256 _roundId) external view returns (int256 answer) {
        (, answer, , , ) = getRoundData(uint80(_roundId));
    }

    function getTimestamp(
        uint256 _roundId
    ) external view returns (uint256 timestamp) {
        (, , timestamp, , ) = getRoundData(uint80(_roundId));
    }

    function getRoundData(
        uint80
    ) public view virtual returns (uint80, int256, uint256, uint256, uint80);

    event SetOverrideTimestamp(uint timestamp);
}
