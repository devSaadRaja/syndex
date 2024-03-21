// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

contract Utils is Test {
    function _passTime(uint256 sec) internal {
        vm.warp(block.timestamp + sec);
    }

    function _mineBlock(uint256 blocks) internal {
        vm.roll(block.number + blocks);
    }
}
