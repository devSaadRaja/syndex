// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

contract IssuerTest is Setup {
    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);
        token.transfer(user1, 1 ether);
        token.transfer(user2, 1 ether);
        vm.stopPrank();
    }

    function testSFCXIssueSynths() public {
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0);
        assertEq(proxycfUSD.balanceOf(user2), 0);

        vm.startPrank(user1);

        syndex.createMaxSynths();

        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1.65 ether);

        syndex.createMaxSynths();

        aggregatorCollateral.setPrice(1.2 ether); // over-collateralized

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 1.65 ether);
        assertEq(syndexDebtShare.balanceOf(user1), 1.65 ether);
        assertEq(syndexDebtShare.balanceOf(user2), 0);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1.65 ether);
        assertEq(proxycfUSD.balanceOf(user2), 0);

        syndex.createMaxSynths();

        vm.stopPrank();

        vm.startPrank(user2);
        syndex.createMaxSynths();
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 5.94 ether);
        assertEq(syndexDebtShare.balanceOf(user1), 1.98 ether);
        assertEq(syndexDebtShare.balanceOf(user2), 3.96 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1.98 ether);
        assertEq(proxycfUSD.balanceOf(user2), 3.96 ether);
    }

    function testSFCXBurnSynths() public {
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxySFCX.balanceOf(user3), 15 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0);
        assertEq(proxycfUSD.balanceOf(user2), 0);
        assertEq(proxycfUSD.balanceOf(user3), 0);

        vm.startPrank(user1);
        syndex.createSynths(1 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        syndex.createSynths(1 ether);
        vm.stopPrank();

        vm.startPrank(user3);
        syndex.createSynths(1 ether);
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 3 ether);
        assertEq(syndexDebtShare.balanceOf(user1), 1 ether);
        assertEq(syndexDebtShare.balanceOf(user2), 1 ether);
        assertEq(syndexDebtShare.balanceOf(user3), 1 ether);

        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxySFCX.balanceOf(user3), 15 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1 ether);
        assertEq(proxycfUSD.balanceOf(user2), 1 ether);
        assertEq(proxycfUSD.balanceOf(user3), 1 ether);

        aggregatorCollateral.setPrice(0.5 ether); // under-collateralized

        vm.startPrank(user1);
        // syndex.burnSynths(1 ether);
        syndex.burnSynthsToTarget();
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 2.825 ether);
        assertEq(syndexDebtShare.balanceOf(user1), 0.825 ether);
        assertEq(syndexDebtShare.balanceOf(user2), 1 ether);
        assertEq(syndexDebtShare.balanceOf(user3), 1 ether);

        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxySFCX.balanceOf(user3), 15 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0.825 ether);
        assertEq(proxycfUSD.balanceOf(user2), 1 ether);
        assertEq(proxycfUSD.balanceOf(user3), 1 ether);
    }

    function testSFCXLiquidateSelf() public {
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0);

        vm.startPrank(user1);
        syndex.createSynths(1 ether);

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 1 ether);
        assertEq(syndexDebtShare.balanceOf(user1), 1 ether);

        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1 ether);

        aggregatorCollateral.setPrice(0.5 ether); // under-collateralized

        syndex.liquidateSelf();
        vm.stopPrank();

        assertLt(syndexDebtShare.calculateTotalSupplyForPeriod(1), 1 ether);
        assertLt(syndexDebtShare.balanceOf(user1), 1 ether);

        assertLt(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1 ether);
    }

    function testSFCXForceLiquidate() public {
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0);

        vm.startPrank(user1);
        syndex.createSynths(1 ether);
        vm.stopPrank();

        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1 ether);

        aggregatorCollateral.setPrice(0.25 ether); // under-collateralized

        liquidator.flagAccountForLiquidation(user1);

        _passTime(28810);

        syndex.liquidateDelinquentAccount(user1);

        assertEq(proxySFCX.balanceOf(user1), 0);
        assertEq(proxycfUSD.balanceOf(user1), 1 ether);
    }

    function testEthIssueSynths() public {
        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 0);
        assertEq(syndexDebtShare.balanceOf(user1), 0);
        assertEq(address(user1).balance, 100 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0);

        vm.startPrank(user1);
        syndex.createSynths(1 ether);
        collateralETH.open{value: 0.15 ether}(0.1 ether, "cfUSD");
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 1 ether);
        assertEq(syndexDebtShare.balanceOf(user1), 1 ether);
        assertEq(address(user1).balance, 99.85 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1.1 ether);

        assertEq(collateralManager.state().totalLoans(), 1);
        (uint long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0.1 ether);
        (uint cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0.1 ether);
    }

    function testEthBurnSynths() public {
        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 0);

        assertEq(syndexDebtShare.balanceOf(user1), 0);
        assertEq(address(user1).balance, 100 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0);

        assertEq(syndexDebtShare.balanceOf(user2), 0);
        assertEq(address(user2).balance, 100 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxycfUSD.balanceOf(user2), 0);

        assertEq(collateralManager.state().totalLoans(), 0);
        (uint long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0);
        (uint cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0);

        vm.startPrank(user1);
        syndex.createSynths(1 ether);
        uint256 id = collateralETH.open{value: 0.15 ether}(0.1 ether, "cfUSD");
        vm.stopPrank();

        vm.startPrank(user2);
        syndex.createSynths(1 ether);
        collateralETH.open{value: 0.15 ether}(0.1 ether, "cfUSD");
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 2 ether);

        assertEq(syndexDebtShare.balanceOf(user1), 1 ether);
        assertEq(address(user1).balance, 99.85 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1.1 ether);

        assertEq(syndexDebtShare.balanceOf(user2), 1 ether);
        assertEq(address(user2).balance, 99.85 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxycfUSD.balanceOf(user2), 1.1 ether);

        assertEq(collateralManager.state().totalLoans(), 2);
        (long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0.2 ether);
        (cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0.2 ether);

        vm.startPrank(user1);
        collateralETH.close(id);
        collateralETH.claim(0.15 ether);
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 2 ether);

        assertEq(syndexDebtShare.balanceOf(user1), 1 ether);
        assertEq(address(user1).balance, 100 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1 ether);

        assertEq(syndexDebtShare.balanceOf(user2), 1 ether);
        assertEq(address(user2).balance, 99.85 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxycfUSD.balanceOf(user2), 1.1 ether);

        assertEq(collateralManager.state().totalLoans(), 2);
        (long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0.1 ether);
        (cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0.1 ether);
    }

    function testEthLiquidate() public {
        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 0);
        assertEq(syndexDebtShare.balanceOf(user1), 0);
        assertEq(address(user1).balance, 100 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0);

        assertEq(collateralManager.state().totalLoans(), 0);
        (uint long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0);
        (uint cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0);

        vm.startPrank(user1);
        syndex.createSynths(1 ether);
        uint256 id = collateralETH.open{value: 0.15 ether}(0.1 ether, "cfUSD");
        vm.stopPrank();

        vm.startPrank(owner);
        aggregatorSynth.setPrice(0.8 * 10 ** 8); // under-collateralized
        vm.stopPrank();

        vm.startPrank(user1);
        collateralETH.liquidate(user1, id, 0.15 ether);
        collateralETH.claim(0.07 ether);
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 1 ether);
        assertEq(syndexDebtShare.balanceOf(user1), 1 ether);
        assertEq(address(user1).balance, 99.92 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1.04 ether + 1);

        assertEq(collateralManager.state().totalLoans(), 1);
        (long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0.04 ether + 1);
        (cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0.04 ether + 1);
    }

    function testErc20IssueSynths() public {
        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 0);
        assertEq(syndexDebtShare.balanceOf(user1), 0);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0);
        assertEq(token.balanceOf(user1), 1 ether);

        vm.startPrank(user1);
        syndex.createSynths(1 ether);
        token.approve(address(collateralErc20), 1 ether);
        collateralErc20.open(0.15 ether, 0.1 ether, "cfUSD");
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 1 ether);
        assertEq(syndexDebtShare.balanceOf(user1), 1 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1.1 ether);
        assertEq(token.balanceOf(user1), 0.85 ether);

        assertEq(collateralManager.state().totalLoans(), 1);
        (uint long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0.1 ether);
        (uint cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0.1 ether);
    }

    function testErc20BurnSynths() public {
        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 0);

        assertEq(syndexDebtShare.balanceOf(user1), 0);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0);
        assertEq(token.balanceOf(user1), 1 ether);

        assertEq(syndexDebtShare.balanceOf(user2), 0);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxycfUSD.balanceOf(user2), 0);
        assertEq(token.balanceOf(user2), 1 ether);

        assertEq(collateralManager.state().totalLoans(), 0);
        (uint long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0);
        (uint cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0);

        vm.startPrank(user1);
        syndex.createSynths(1 ether);
        token.approve(address(collateralErc20), 1 ether);
        uint256 id = collateralErc20.open(0.15 ether, 0.1 ether, "cfUSD");
        vm.stopPrank();

        vm.startPrank(user2);
        syndex.createSynths(1 ether);
        token.approve(address(collateralErc20), 1 ether);
        collateralErc20.open(0.15 ether, 0.1 ether, "cfUSD");
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 2 ether);

        assertEq(syndexDebtShare.balanceOf(user1), 1 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1.1 ether);
        assertEq(token.balanceOf(user1), 0.85 ether);

        assertEq(syndexDebtShare.balanceOf(user2), 1 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxycfUSD.balanceOf(user2), 1.1 ether);
        assertEq(token.balanceOf(user2), 0.85 ether);

        assertEq(collateralManager.state().totalLoans(), 2);
        (long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0.2 ether);
        (cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0.2 ether);

        vm.startPrank(user1);
        collateralErc20.close(id);
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 2 ether);

        assertEq(syndexDebtShare.balanceOf(user1), 1 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1 ether);
        assertEq(token.balanceOf(user1), 1 ether);

        assertEq(syndexDebtShare.balanceOf(user2), 1 ether);
        assertEq(proxySFCX.balanceOf(user2), 10 ether);
        assertEq(proxycfUSD.balanceOf(user2), 1.1 ether);
        assertEq(token.balanceOf(user2), 0.85 ether);

        assertEq(collateralManager.state().totalLoans(), 2);
        (long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0.1 ether);
        (cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0.1 ether);
    }

    function testErc20Liquidate() public {
        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 0);
        assertEq(syndexDebtShare.balanceOf(user1), 0);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 0);
        assertEq(token.balanceOf(user1), 1 ether);

        assertEq(collateralManager.state().totalLoans(), 0);
        (uint long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0);
        (uint cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0);

        vm.startPrank(user1);
        syndex.createSynths(1 ether);
        token.approve(address(collateralErc20), 1 ether);
        uint256 id = collateralErc20.open(0.15 ether, 0.1 ether, "cfUSD");
        vm.stopPrank();

        vm.startPrank(owner);
        aggregatorSynth.setPrice(0.8 * 10 ** 8); // under-collateralized
        vm.stopPrank();

        vm.startPrank(user1);
        // uint256 liquidationAmount = collateralErc20.liquidationAmount(id);
        collateralErc20.liquidate(user1, id, 0.05 ether);
        vm.stopPrank();

        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 1 ether);
        assertEq(syndexDebtShare.balanceOf(user1), 1 ether);
        assertEq(proxySFCX.balanceOf(user1), 5 ether);
        assertEq(proxycfUSD.balanceOf(user1), 1.05 ether);
        assertEq(token.balanceOf(user1), 0.9125 ether);

        assertEq(collateralManager.state().totalLoans(), 1);
        (long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0.05 ether);
        (cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0.05 ether);
    }
}
