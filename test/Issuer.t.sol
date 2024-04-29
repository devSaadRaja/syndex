// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

contract IssuerTest is Setup {
    function testSNXIssueSynths() public {
        console.log();
        console.log("---USER 1---");
        vm.startPrank(user1);

        console.log("FIRST ISSUE");
        synthetix.issueMaxSynths();

        console.log("SECOND ISSUE");
        synthetix.issueMaxSynths();

        // over-collateralized
        aggregatorCollateral.setPrice(1.2 * 10 ** 18);

        console.log("THIRD ISSUE");
        synthetix.issueMaxSynths();

        vm.stopPrank();

        console.log();
        console.log("---USER 2---");
        vm.startPrank(user2);

        console.log("FIRST ISSUE");
        synthetix.issueSynths(1 * 10 ** 18);

        vm.stopPrank();

        // totalSupplyOnPeriod
        assertEq(synthetixDebtShare.totalSupplyOnPeriod(1), 2.2 * 10 ** 18);
        // accountBalance
        assertEq(synthetixDebtShare.balanceOf(user1), 1.2 * 10 ** 18);
        assertEq(synthetixDebtShare.balanceOf(user2), 1 * 10 ** 18);
    }

    function testSNXBurnSynths() public {
        console.log();
        console.log("---ISSUE USER 1---");
        vm.startPrank(user1);
        synthetix.issueSynths(1 * 10 ** 18);
        vm.stopPrank();

        console.log();
        console.log("---ISSUE USER 2---");
        vm.startPrank(user2);
        synthetix.issueSynths(1 * 10 ** 18);
        vm.stopPrank();

        console.log();
        console.log("---ISSUE USER 3---");
        vm.startPrank(user3);
        synthetix.issueSynths(1 * 10 ** 18);
        vm.stopPrank();

        // under-collateralized
        aggregatorCollateral.setPrice(0.5 * 10 ** 18);

        console.log();
        console.log("---BURN USER 1---");
        vm.startPrank(user1);
        // synthetix.burnSynths(1 * 10 ** 18);
        synthetix.burnSynthsToTarget();
        vm.stopPrank();
    }

    function testSNXLiquidateSelf() public {
        vm.startPrank(user1);

        console.log("ISSUE");
        synthetix.issueSynths(1 * 10 ** 18);

        // under-collateralized
        aggregatorCollateral.setPrice(0.5 * 10 ** 18);

        console.log("LIQUIDATE");
        synthetix.liquidateSelf();

        vm.stopPrank();
    }

    function testSNXForceLiquidate() public {
        vm.startPrank(user1);
        console.log("ISSUE");
        synthetix.issueSynths(1 * 10 ** 18);
        vm.stopPrank();

        // under-collateralized
        aggregatorCollateral.setPrice(0.25 * 10 ** 18);

        console.log("FLAG FOR LIQUIDATION");
        liquidator.flagAccountForLiquidation(user1);

        _passTime(28810);

        console.log("LIQUIDATE");
        synthetix.liquidateDelinquentAccount(user1);
    }

    function testEthIssueSynths() public {
        vm.startPrank(user1);
        console.log("ISSUE");

        synthetix.issueSynths(1 * 10 ** 18);
        collateralETH.open{value: 0.15 ether}(0.1 * 10 ** 18, "sUSD");

        vm.stopPrank();
    }

    function testEthBurnSynths() public {
        console.log();
        console.log("---USER 1---");
        vm.startPrank(user1);

        console.log("ISSUE");
        synthetix.issueSynths(1 * 10 ** 18);
        uint256 id = collateralETH.open{value: 0.15 ether}(
            0.1 * 10 ** 18,
            "sUSD"
        );
        vm.stopPrank();

        console.log();
        console.log("---USER 2---");
        vm.startPrank(user2);

        console.log("ISSUE");
        synthetix.issueSynths(1 * 10 ** 18);
        collateralETH.open{value: 0.15 ether}(0.1 * 10 ** 18, "sUSD");
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
        synthetix.issueSynths(1 * 10 ** 18);
        uint256 id = collateralETH.open{value: 0.15 ether}(
            0.1 * 10 ** 18,
            "sUSD"
        );

        // under-collateralized
        aggregatorETH.setPrice(0.8 * 10 ** 18);

        console.log("LIQUIDATE");
        collateralETH.liquidate(user1, id, 0.1 * 10 ** 18);

        vm.stopPrank();
    }
}
