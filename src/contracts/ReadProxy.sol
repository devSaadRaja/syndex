// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ReadProxy is Ownable {
    address public currentTarget;

    constructor(address _owner) Ownable(_owner) {}

    function updateTarget(address _target) external onlyOwner {
        currentTarget = _target;
        emit TargetUpdated(currentTarget);
    }

    fallback() external payable {
        // The basics of a proxy read call
        // Note that msg.sender in the underlying will always be the address of this contract.
        assembly {
            calldatacopy(0, 0, calldatasize())

            // Use of staticcall - this will revert if the underlying function mutates state
            let result := staticcall(
                gas(),
                sload(currentTarget.slot),
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            if iszero(result) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    receive() external payable {}

    event TargetUpdated(address newTarget);
}
