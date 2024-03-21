// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseRewardEscrowV2.sol";

contract RewardEscrowV2 is BaseRewardEscrowV2 {
    using SafeMath for uint;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYNTHETIX_BRIDGE_OPTIMISM =
        "SynthetixBridgeToOptimism";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _resolver
    ) BaseRewardEscrowV2(_owner, _resolver) {}

    /* ========== VIEWS ======================= */

    function resolverAddressesRequired()
        public
        view
        override
        returns (bytes32[] memory addresses)
    {
        bytes32[] memory existingAddresses = BaseRewardEscrowV2
            .resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_SYNTHETIX_BRIDGE_OPTIMISM;
        return combineArrays(existingAddresses, newAddresses);
    }

    function synthetixBridgeToOptimism() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_SYNTHETIX_BRIDGE_OPTIMISM);
    }

    /* ========== L2 MIGRATION ========== */

    function burnForMigration(
        address account,
        uint[] calldata entryIDs
    )
        external
        override
        onlySynthetixBridge
        returns (
            uint256 escrowedAccountBalance,
            VestingEntries.VestingEntry[] memory vestingEntries
        )
    {
        require(entryIDs.length > 0, "Entry IDs required");

        vestingEntries = new VestingEntries.VestingEntry[](entryIDs.length);

        for (uint i = 0; i < entryIDs.length; i++) {
            VestingEntries.VestingEntry memory entry = vestingSchedules(
                account,
                entryIDs[i]
            );

            // only unvested
            if (entry.escrowAmount > 0) {
                vestingEntries[i] = entry;

                /* add the escrow amount to escrowedAccountBalance */
                escrowedAccountBalance = escrowedAccountBalance.add(
                    entry.escrowAmount
                );

                /* Delete the vesting entry being migrated */
                state().setZeroAmount(account, entryIDs[i]);
            }
        }

        /**
         *  update account total escrow balances for migration
         *  transfer the escrowed SNX being migrated to the L2 deposit contract
         */
        if (escrowedAccountBalance > 0) {
            state().updateEscrowAccountBalance(
                account,
                -SafeCast.toInt256(escrowedAccountBalance)
            );
            synthetixERC20().transfer(
                synthetixBridgeToOptimism(),
                escrowedAccountBalance
            );
        }

        emit BurnedForMigrationToL2(
            account,
            entryIDs,
            escrowedAccountBalance,
            block.timestamp
        );

        return (escrowedAccountBalance, vestingEntries);
    }

    /* ========== MODIFIERS ========== */

    modifier onlySynthetixBridge() {
        require(
            msg.sender == synthetixBridgeToOptimism(),
            "Can only be invoked by SynthetixBridgeToOptimism contract"
        );
        _;
    }

    /* ========== EVENTS ========== */
    event BurnedForMigrationToL2(
        address indexed account,
        uint[] entryIDs,
        uint escrowedAmountMigrated,
        uint time
    );
}
