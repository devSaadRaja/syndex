// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PriceOracle {
    int256 price;

    constructor(int256 _price) {
        price = _price;
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (1, price, 1, 1, 1);
    }
}
