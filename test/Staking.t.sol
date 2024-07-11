// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

import {Staking} from "../src/contracts/staking/Staking.sol";

contract StakingTest is Setup {
    Staking public staking;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);

        staking = new Staking(address(proxySFCX), address(proxySFCX));
        proxySFCX.transfer(address(staking), 30 ether);

        vm.stopPrank();
    }

    function testStakeSFCX() public {
        vm.startPrank(user7); // user7

        proxySFCX.approve(address(staking), 10 ether);
        staking.stake(10 ether);
        assertEq(staking.totalStaked(), 10 ether);
        assertEq(staking.getStakeDetails(user7).balance, 10 ether);

        proxySFCX.approve(address(staking), 10 ether);
        staking.stake(10 ether);
        assertEq(staking.totalStaked(), 20 ether);
        assertEq(staking.getStakeDetails(user7).balance, 20 ether);

        vm.stopPrank();

        vm.startPrank(user8); // user8

        proxySFCX.approve(address(staking), 10 ether);
        staking.stake(10 ether);
        assertEq(staking.totalStaked(), 30 ether);
        assertEq(staking.getStakeDetails(user8).balance, 10 ether);

        vm.stopPrank();
    }

    function testClaimRewardsSFCX() public {
        vm.startPrank(user8);

        proxySFCX.approve(address(staking), 10 ether);
        staking.stake(10 ether);

        _passTime(365 days);

        assertEq(staking.calculateRewards(user8), 1.4 ether);
        staking.claimReward();

        _passTime(365 days);

        assertEq(staking.calculateRewards(user8), 1.4 ether);
        staking.claimReward();

        vm.stopPrank();
    }

    function testUnstakeSFCX() public {
        vm.startPrank(user8);

        proxySFCX.approve(address(staking), 10 ether);
        staking.stake(10 ether);

        _passTime(365 days);

        assertEq(staking.calculateRewards(user8), 1.4 ether);
        staking.unstake(5 ether);

        assertEq(staking.calculateRewards(user8), 0);

        vm.stopPrank();
    }

    function testWarmupPeriodSFCX() public {
        vm.startPrank(owner);
        staking.setWarmupPeriod(2 days);
        vm.stopPrank();

        vm.startPrank(user8);
        proxySFCX.approve(address(staking), 10 ether);
        staking.stake(10 ether);
        _passTime(1 days);
        vm.expectRevert("Warmup Period not Ended!");
        staking.claimReward();
        vm.expectRevert("Warmup Period not Ended!");
        staking.unstake(5 ether);
        vm.stopPrank();
    }
}
