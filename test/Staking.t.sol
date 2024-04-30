// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

import {SMX} from "../src/contracts/SMX/SMX.sol";
import {Staking} from "../src/contracts/staking/Staking.sol";

contract StakingTest is Setup {
    Staking public staking;

    function setUp() public override {
        vm.startPrank(owner);
        smx = new SMX("SMX", "SMX", owner, 100_000_000 ether);
        staking = new Staking(address(smx), address(smx));
        smx.transfer(user1, 20 * 10 ** 18);
        smx.transfer(user2, 20 * 10 ** 18);
        smx.transfer(address(staking), 30 * 10 ** 18);
        vm.stopPrank();
    }

    function testStake() public {
        vm.startPrank(user1); // user1

        smx.approve(address(staking), 10 * 10 ** 18);
        staking.stake(10 * 10 ** 18);
        assertEq(staking.totalStaked(), 10 * 10 ** 18);
        assertEq(staking.getStakeDetails(user1).balance, 10 * 10 ** 18);

        smx.approve(address(staking), 10 * 10 ** 18);
        staking.stake(10 * 10 ** 18);
        assertEq(staking.totalStaked(), 20 * 10 ** 18);
        assertEq(staking.getStakeDetails(user1).balance, 20 * 10 ** 18);

        vm.stopPrank();

        vm.startPrank(user2); // user2

        smx.approve(address(staking), 10 * 10 ** 18);
        staking.stake(10 * 10 ** 18);
        assertEq(staking.totalStaked(), 30 * 10 ** 18);
        assertEq(staking.getStakeDetails(user2).balance, 10 * 10 ** 18);

        vm.stopPrank();
    }

    function testClaimRewards() public {
        vm.startPrank(user1);

        smx.approve(address(staking), 10 * 10 ** 18);
        staking.stake(10 * 10 ** 18);

        _passTime(365 days);

        assertEq(staking.calculateRewards(user1), 1.4 ether);
        staking.claimReward();

        _passTime(365 days);

        assertEq(staking.calculateRewards(user1), 1.4 ether);
        staking.claimReward();

        vm.stopPrank();
    }

    function testUnstake() public {
        vm.startPrank(user1);

        smx.approve(address(staking), 10 * 10 ** 18);
        staking.stake(10 * 10 ** 18);

        _passTime(365 days);

        assertEq(staking.calculateRewards(user1), 1.4 ether);
        staking.unstake(5 * 10 ** 18);

        assertEq(staking.calculateRewards(user1), 0);

        vm.stopPrank();
    }
}
