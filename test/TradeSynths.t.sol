// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TradeSynthsTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function testTradeSynths() public {
        vm.startPrank(user4);
        IERC20(address(proxySNX)).transfer(address(tradingRewards), 250 ether);
        IERC20(address(proxySNX)).transfer(
            address(rewardsDistribution),
            250 ether
        );
        vm.stopPrank();

        vm.startPrank(owner);
        synthetix.issueMaxSynths();

        synthetix.exchange("sUSD", 100 ether, "sETH");

        tradingRewards.closeCurrentPeriodWithRewards(
            tradingRewards.getPeriodRecordedFees(0)
        );

        // rewardsDistribution.distributeRewards(
        //     tradingRewards.getPeriodRecordedFees(0)
        // );

        assertEq(tradingRewards.getPeriodAvailableRewards(0), 200);
        assertEq(tradingRewards.getPeriodIsClaimable(0), true);
        assertEq(tradingRewards.getPeriodRecordedFees(0), 200);
        assertEq(tradingRewards.getAvailableRewards(), 200);
        assertEq(
            tradingRewards.getAvailableRewardsForAccountForPeriod(owner, 0),
            200
        );

        console.log(tradingRewards.getPeriodRecordedFees(0));
        console.log(tradingRewards.getPeriodIsClaimable(0));
        console.log(tradingRewards.getAvailableRewards());
        console.log(
            "getPeriodAvailableRewards(0)",
            tradingRewards.getPeriodAvailableRewards(0)
        );
        console.log(
            "getAvailableRewardsForAccountForPeriod(owner, 0)",
            tradingRewards.getAvailableRewardsForAccountForPeriod(owner, 0)
        );

        vm.stopPrank();
    }
}
