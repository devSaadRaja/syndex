// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenTest is Setup {
    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);

        synthetix.mint();

        factory.createPair(address(proxySNX), WETH);

        proxySNX.approve(address(router), 50 * 10 ** 18);
        IERC20(WETH).approve(address(router), 50 * 10 ** 18);

        router.addLiquidity(
            address(proxySNX),
            WETH,
            50 * 10 ** 18,
            50 * 10 ** 18,
            0,
            0,
            owner,
            block.timestamp + 10 minutes
        );

        address pair = factory.getPair(address(proxySNX), WETH);
        synthetix.addPool(pair);

        // synthetix.addTaxExempts(owner);
        // synthetix.addTaxExempts(address(synthetix));

        synthetix.addTaxReceiver(user1, 50);
        synthetix.addTaxReceiver(user2, 50);

        synthetix.setDeploy(true);

        vm.stopPrank();
    }

    function testToken() public {
        vm.startPrank(owner);

        console.log("BEFORE");
        console.log("SNX", proxySNX.balanceOf(owner));
        console.log("WETH", IERC20(WETH).balanceOf(owner));

        proxySNX.approve(address(router), 50 * 10 ** 18);
        address[] memory path = new address[](2);
        path[0] = address(proxySNX);
        path[1] = WETH;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            10 * 10 ** 18,
            0,
            path,
            owner,
            block.timestamp + 10 minutes
        );

        console.log("AFTER");
        console.log("SNX", proxySNX.balanceOf(owner));
        console.log("WETH", IERC20(WETH).balanceOf(owner));

        vm.stopPrank();
    }

    function testTax() public {
        vm.startPrank(owner);

        // SELL
        console.log("SELL");
        _swap(address(proxySNX), WETH, 10 * 10 ** 18, owner);

        // BUY
        console.log("BUY");
        _swap(WETH, address(proxySNX), 10 * 10 ** 18, owner);

        console.log();
        console.log("threshold\n", synthetix.threshold());
        console.log("currentTaxAmount\n", synthetix.currentTaxAmount());
        console.log("balanceOf synthetix\n", synthetix.balanceOf(address(synthetix)));

        proxySNX.transfer(user3, 1 * 10 ** 18);

        vm.stopPrank();

        console.log();
        console.log("BALANCE WETH");
        console.log("user1 balance\n", IERC20(WETH).balanceOf(user1));
        console.log("user2 balance\n", IERC20(WETH).balanceOf(user2));
    }

    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _to
    ) internal {
        IERC20(_tokenIn).approve(address(router), _amountIn);

        address[] memory path;
        if (_tokenIn != address(WETH) && _tokenOut != address(WETH)) {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        } else {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        }

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            0,
            path,
            _to,
            block.timestamp + 10 minutes
        );
    }
}
