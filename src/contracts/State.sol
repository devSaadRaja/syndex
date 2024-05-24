// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract State is Ownable {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner() != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function linkContract(
        address _associatedContract
    ) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract() {
        require(
            msg.sender == associatedContract,
            "Only the associated contract can perform this action"
        );
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}
