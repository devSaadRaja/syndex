// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISynthetixBridgeToOptimism {
    function closeFeePeriod(uint scfxBackedDebt, uint debtSharesSupply) external;

    function migrateEscrow(uint256[][] calldata entryIDs) external;

    function depositTo(address to, uint amount) external;

    function depositReward(uint amount) external;

    function depositAndMigrateEscrow(
        uint256 depositAmount,
        uint256[][] calldata entryIDs
    ) external;
}
