// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

contract IssuerTest is Setup {
    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);
        smx.transfer(user1, 1 ether);
        smx.transfer(user2, 1 ether);
        vm.stopPrank();
    }

    function testSCFXIssueSynths() public {
        console.log();
        console.log("---USER 1---");
        vm.startPrank(user1);

        console.log("FIRST ISSUE");
        synthetix.createMaxSynths();

        console.log("SECOND ISSUE");
        synthetix.createMaxSynths();

        // over-collateralized
        aggregatorCollateral.setPrice(1.2 ether);

        console.log("THIRD ISSUE");
        synthetix.createMaxSynths();

        vm.stopPrank();

        console.log();
        console.log("---USER 2---");
        vm.startPrank(user2);

        console.log("FIRST ISSUE");
        synthetix.createSynths(1 ether);

        vm.stopPrank();

        // calculateTotalSupplyForPeriod
        assertEq(synthetixDebtShare.calculateTotalSupplyForPeriod(1), 2.2 ether);
        // accountBalance
        assertEq(synthetixDebtShare.balanceOf(user1), 1.2 ether);
        assertEq(synthetixDebtShare.balanceOf(user2), 1 ether);
    }

    function testSCFXBurnSynths() public {
        console.log();
        console.log("---ISSUE USER 1---");
        vm.startPrank(user1);
        synthetix.createSynths(1 ether);
        vm.stopPrank();

        console.log();
        console.log("---ISSUE USER 2---");
        vm.startPrank(user2);
        synthetix.createSynths(1 ether);
        vm.stopPrank();

        console.log();
        console.log("---ISSUE USER 3---");
        vm.startPrank(user3);
        synthetix.createSynths(1 ether);
        vm.stopPrank();

        // under-collateralized
        aggregatorCollateral.setPrice(0.5 ether);

        console.log();
        console.log("---BURN USER 1---");
        vm.startPrank(user1);
        // synthetix.burnSynths(1 ether);
        synthetix.burnSynthsToTarget();
        vm.stopPrank();
    }

    function testSCFXLiquidateSelf() public {
        vm.startPrank(user1);

        console.log("ISSUE");
        synthetix.createSynths(1 ether);

        // under-collateralized
        aggregatorCollateral.setPrice(0.5 ether);

        console.log("LIQUIDATE");
        synthetix.liquidateSelf();

        vm.stopPrank();
    }

    function testSCFXForceLiquidate() public {
        vm.startPrank(user1);
        console.log("ISSUE");
        synthetix.createSynths(1 ether);
        vm.stopPrank();

        // under-collateralized
        aggregatorCollateral.setPrice(0.25 ether);

        console.log("FLAG FOR LIQUIDATION");
        liquidator.flagAccountForLiquidation(user1);

        _passTime(28810);

        console.log("LIQUIDATE");
        synthetix.liquidateDelinquentAccount(user1);
    }

    function testEthIssueSynths() public {
        vm.startPrank(user1);
        console.log("ISSUE");

        synthetix.createSynths(1 ether);
        collateralETH.open{value: 0.15 ether}(0.1 ether, "sUSD");

        vm.stopPrank();
    }

    function testEthBurnSynths() public {
        console.log();
        console.log("---USER 1---");
        vm.startPrank(user1);

        console.log("ISSUE");
        synthetix.createSynths(1 ether);
        uint256 id = collateralETH.open{value: 0.15 ether}(0.1 ether, "sUSD");
        vm.stopPrank();

        console.log();
        console.log("---USER 2---");
        vm.startPrank(user2);

        console.log("ISSUE");
        synthetix.createSynths(1 ether);
        collateralETH.open{value: 0.15 ether}(0.1 ether, "sUSD");
        vm.stopPrank();

        console.log();
        console.log("---USER 1---");
        vm.startPrank(user1);
        console.log("BURN / CLOSE");
        collateralETH.close(id);
        vm.stopPrank();
    }

    function testEthLiquidate() public {
        vm.startPrank(user1);

        console.log("ISSUE");
        synthetix.createSynths(1 ether);
        uint256 id = collateralETH.open{value: 0.15 ether}(0.1 ether, "sUSD");

        // under-collateralized
        aggregatorETH.setPrice(0.8 ether);

        console.log("LIQUIDATE");
        collateralETH.liquidate(user1, id, 0.1 ether);

        vm.stopPrank();
    }

    function testErc20IssueSynths() public {
        vm.startPrank(user1);
        console.log("ISSUE");

        synthetix.createSynths(1 ether);

        smx.approve(address(collateralErc20), 50 ether);
        collateralErc20.open(0.15 ether, 0.1 ether, "sUSD");

        vm.stopPrank();
    }

    function testErc20BurnSynths() public {
        console.log();
        console.log("---USER 1---");
        vm.startPrank(user1);

        console.log("ISSUE");
        synthetix.createSynths(1 ether);
        smx.approve(address(collateralErc20), 50 ether);
        uint256 id = collateralErc20.open(0.15 ether, 0.1 ether, "sUSD");
        vm.stopPrank();

        console.log();
        console.log("---USER 2---");
        vm.startPrank(user2);

        console.log("ISSUE");
        synthetix.createSynths(1 ether);
        smx.approve(address(collateralErc20), 50 ether);
        collateralErc20.open(0.15 ether, 0.1 ether, "sUSD");
        vm.stopPrank();

        console.log();
        console.log("---USER 1---");
        vm.startPrank(user1);
        console.log("BURN / CLOSE");
        collateralErc20.close(id);
        vm.stopPrank();
    }

    function testErc20Liquidate() public {
        vm.startPrank(user1);

        console.log("ISSUE");
        synthetix.createSynths(1 ether);
        smx.approve(address(collateralErc20), 50 ether);
        uint256 id = collateralErc20.open(0.15 ether, 0.1 ether, "sUSD");

        // under-collateralized
        aggregatorETH.setPrice(0.8 ether);

        console.log("LIQUIDATE");
        collateralErc20.liquidate(user1, id, 0.1 ether);

        vm.stopPrank();
    }
}
