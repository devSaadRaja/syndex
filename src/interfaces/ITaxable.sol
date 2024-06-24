// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITaxable {
    function distribute() external;

    function distributeTax() external;

    function threshold() external returns (uint256);

    function rewardAddr() external returns (address);

    function routerAddr() external returns (address);

    function pool(address addr) external returns (bool);

    function currentFeeAmount() external returns (uint256);

    function addToCurrentFeeAmount(uint256 amount) external;

    function feePercentage(address addr) external returns (uint256);

    function isExcludedFromFee(address addr) external returns (bool);

    function getTaxAmount(uint256 _amount, bool buy) external returns (uint256);

    function calculateTransferAmount(
        uint256 _amount,
        uint256 _fee
    ) external returns (uint256);
}
