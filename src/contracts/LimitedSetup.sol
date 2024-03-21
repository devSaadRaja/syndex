// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract LimitedSetup {
    uint public setupExpiryTime;

    /**
     * @dev LimitedSetup Constructor.
     * @param setupDuration The time the setup period will last for.
     */
    constructor(uint setupDuration) {
        setupExpiryTime = block.timestamp + setupDuration;
    }

    modifier onlyDuringSetup() {
        require(
            block.timestamp < setupExpiryTime,
            "Can only perform this action during setup"
        );
        _;
    }
}
