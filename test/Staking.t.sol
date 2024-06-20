// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

import {SMX} from "../src/contracts/SMX/SMX.sol";
import {Staking} from "../src/contracts/staking/Staking.sol";

contract StakingTest is Setup {
    Staking public staking;
    Staking public stakingSCFX;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);

        smx = new SMX("SMX", "SMX", owner, 100_000_000 ether);
        staking = new Staking(address(smx), address(smx));
        smx.transfer(user1, 20 * 10 ** 18);
        smx.transfer(user2, 20 * 10 ** 18);
        smx.transfer(address(staking), 30 * 10 ** 18);

        stakingSCFX = new Staking(address(proxySCFX), address(proxySCFX));
        proxySCFX.transfer(address(stakingSCFX), 30 ether);

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

    function testWarmupPeriod() public {
        vm.startPrank(owner);
        staking.setWarmupPeriod(2 days);
        vm.stopPrank();

        vm.startPrank(user1);
        smx.approve(address(staking), 10 ether);
        staking.stake(10 ether);
        _passTime(1 days);
        vm.expectRevert("Warmup Period not Ended!");
        staking.claimReward();
        vm.expectRevert("Warmup Period not Ended!");
        staking.unstake(5 ether);
        vm.stopPrank();
    }

    function testStakeSCFX() public {
        vm.startPrank(user7); // user7

        proxySCFX.approve(address(stakingSCFX), 10 ether);
        stakingSCFX.stake(10 ether);
        assertEq(stakingSCFX.totalStaked(), 10 ether);
        assertEq(stakingSCFX.getStakeDetails(user7).balance, 10 ether);

        proxySCFX.approve(address(stakingSCFX), 10 ether);
        stakingSCFX.stake(10 ether);
        assertEq(stakingSCFX.totalStaked(), 20 ether);
        assertEq(stakingSCFX.getStakeDetails(user7).balance, 20 ether);

        vm.stopPrank();

        vm.startPrank(user8); // user8

        proxySCFX.approve(address(stakingSCFX), 10 ether);
        stakingSCFX.stake(10 ether);
        assertEq(stakingSCFX.totalStaked(), 30 ether);
        assertEq(stakingSCFX.getStakeDetails(user8).balance, 10 ether);

        vm.stopPrank();
    }

    function testClaimRewardsSCFX() public {
        vm.startPrank(user8);

        proxySCFX.approve(address(stakingSCFX), 10 ether);
        stakingSCFX.stake(10 ether);

        _passTime(365 days);

        assertEq(stakingSCFX.calculateRewards(user8), 1.4 ether);
        stakingSCFX.claimReward();

        _passTime(365 days);

        assertEq(stakingSCFX.calculateRewards(user8), 1.4 ether);
        stakingSCFX.claimReward();

        vm.stopPrank();
    }

    function testUnstakeSCFX() public {
        vm.startPrank(user8);

        proxySCFX.approve(address(stakingSCFX), 10 ether);
        stakingSCFX.stake(10 ether);

        _passTime(365 days);

        assertEq(stakingSCFX.calculateRewards(user8), 1.4 ether);
        stakingSCFX.unstake(5 ether);

        assertEq(stakingSCFX.calculateRewards(user8), 0);

        vm.stopPrank();
    }

    function testWarmupPeriodSCFX() public {
        vm.startPrank(owner);
        stakingSCFX.setWarmupPeriod(2 days);
        vm.stopPrank();

        vm.startPrank(user8);
        proxySCFX.approve(address(stakingSCFX), 10 ether);
        stakingSCFX.stake(10 ether);
        _passTime(1 days);
        vm.expectRevert("Warmup Period not Ended!");
        stakingSCFX.claimReward();
        vm.expectRevert("Warmup Period not Ended!");
        stakingSCFX.unstake(5 ether);
        vm.stopPrank();
    }
}
