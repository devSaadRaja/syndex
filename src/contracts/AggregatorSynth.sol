// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AddressResolver.sol";

contract AggregatorSynth is AccessControl {
    bytes32 public constant PRICE_SETTER_ROLE = keccak256("PRICE_SETTER_ROLE");

    string private _description;
    int256 private _currentPrice;
    uint80 private _latestRound;

    AddressResolver public resolver;

    constructor(
        string memory __description,
        int256 initialPrice,
        address _resolver
    ) {
        _description = __description;
        _currentPrice = initialPrice;
        resolver = AddressResolver(_resolver);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PRICE_SETTER_ROLE, msg.sender);
    }

    function description() external view returns (string memory) {
        return _description;
    }

    function decimals() external view returns (uint8) {
        return 8;
    }

    function setPrice(int256 price) external onlyRole(PRICE_SETTER_ROLE) {
        _currentPrice = price;
    }

    function latestAnswer() external view returns (int256) {
        return _currentPrice;
    }

    function latestRound() external view returns (uint256) {
        return _latestRound;
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            _roundId,
            _currentPrice,
            block.timestamp,
            block.timestamp,
            _roundId
        );
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            _latestRound,
            _currentPrice,
            block.timestamp,
            block.timestamp,
            _latestRound
        );
    }
}
