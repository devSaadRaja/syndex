// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {ISwapRouter} from "../src/contracts/SMX/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "../src/contracts/SMX/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "../src/contracts/SMX/interfaces/IUniswapV3Factory.sol";
import {INonfungiblePositionManager} from "../src/contracts/SMX/interfaces/INonfungiblePositionManager.sol";

import {RewardEscrow} from "../src/contracts/SMX/RewardEscrow.sol";
import {vSMXRedeemer} from "../src/contracts/SMX/vSMXRedeemer.sol";
import {SupplySchedule} from "../src/contracts/SMX/SupplySchedule.sol";
import {MultipleMerkleDistributor} from "../src/contracts/SMX/MultipleMerkleDistributor.sol";

contract SMXTest is Setup {
    ISwapRouter swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV3Factory v3factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    INonfungiblePositionManager nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    RewardEscrow public rewardEscrow2;
    vSMXRedeemer public vSmxRedeemer;
    SupplySchedule public supplySchedule2;
    MultipleMerkleDistributor public multipleMerkleDistributor;

    function setUp() public override {
        super.setUp();

        vm.startPrank(address(issuer));
        synthsUSD.issue(owner, 1000 ether);
        synthsUSD.issue(user1, 1000 ether);
        vm.stopPrank();

        vm.startPrank(owner);

        synthetix.exchange("sUSD", 500 ether, "sETH");

        factory.createPair(address(proxysUSD), address(proxysETH));

        IERC20(address(proxysUSD)).approve(address(router), 50 ether);
        IERC20(address(proxysETH)).approve(address(router), 50 ether);
        router.addLiquidity(
            address(proxysUSD),
            address(proxysETH),
            50 ether,
            50 ether,
            0,
            0,
            owner,
            block.timestamp + 10 minutes
        );

        supplySchedule2 = new SupplySchedule(owner, treasury);
        // vSmxRedeemer = new vSMXRedeemer(address(smx), address(smx));
        rewardEscrow2 = new RewardEscrow(owner, address(smx));
        multipleMerkleDistributor = new MultipleMerkleDistributor(
            owner,
            address(smx),
            address(rewardEscrow2)
        );

        smx.approve(address(router), 50 ether);
        IERC20(WETH).approve(address(router), 50 ether);
        router.addLiquidity(
            address(smx),
            WETH,
            50 ether,
            50 ether,
            0,
            0,
            owner,
            block.timestamp + 10 minutes
        );

        supplySchedule2.setSMX(address(smx));
        supplySchedule2.setStakingRewards(address(stakingAddr));
        supplySchedule2.setTradingRewards(address(multipleMerkleDistributor));

        // multipleMerkleDistributor.setMerkleRootForEpoch();

        vm.stopPrank();
    }

    function testUniswapV3() public {
        vm.startPrank(owner);

        // ! MAKE POOL ---

        v3factory.createPool(address(proxysUSD), address(proxysETH), 3000); // take care of sequence of tokens
        address pool = v3factory.getPool(
            address(proxysUSD),
            address(proxysETH),
            3000
        );

        IUniswapV3Pool v3Pool = IUniswapV3Pool(pool);
        v3Pool.initialize(792281625142644000000000000000);

        // ! ADD LIQUIDITY ---

        IERC20(address(proxysUSD)).approve(
            address(nonfungiblePositionManager),
            50 ether
        );
        IERC20(address(proxysETH)).approve(
            address(nonfungiblePositionManager),
            50 ether
        );

        int24 tickSpacing = v3Pool.tickSpacing();
        uint128 liquidity = v3Pool.liquidity();
        uint24 fee = v3Pool.fee();
        (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        ) = v3Pool.slot0();

        console.log("liquidity BEFORE", liquidity);
        console.log("tickSpacing", uint24(tickSpacing));
        console.log("fee", fee);
        console.log("sqrtPriceX96", sqrtPriceX96);
        console.log("tick", uint24(tick));
        console.log("observationIndex", uint16(observationIndex));
        console.log("observationCardinality", uint16(observationCardinality));
        console.log(
            "observationCardinalityNext",
            uint16(observationCardinalityNext)
        );
        console.log("feeProtocol", uint16(feeProtocol));
        console.log("unlocked", unlocked);

        // tickLower = nearestUsableTick(tick, tickSpacing) - tickSpacing * 2;
        // tickUpper = nearestUsableTick(tick, tickSpacing) + tickSpacing * 2;

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: address(proxysUSD),
                token1: address(proxysETH),
                fee: fee,
                tickLower: 45960,
                tickUpper: 46200,
                amount0Desired: 50 ether,
                amount1Desired: 50 ether,
                amount0Min: 0,
                amount1Min: 0,
                recipient: owner,
                deadline: block.timestamp + 10 minutes
            });

        nonfungiblePositionManager.mint(params);

        // ! SWAP ---

        // IERC20(address(proxysUSD)).approve(address(swapRouter), 10 ether);
        // ISwapRouter.ExactInputSingleParams memory inputParams = ISwapRouter
        //     .ExactInputSingleParams({
        //         tokenIn: address(proxysUSD),
        //         tokenOut: address(proxysETH),
        //         fee: fee,
        //         recipient: owner,
        //         deadline: block.timestamp + 10 minutes,
        //         amountIn: 1 ether,
        //         amountOutMinimum: 0,
        //         sqrtPriceLimitX96: 0
        //     });

        // uint256 amountOut = swapRouter.exactInputSingle(inputParams);
        // console.log("amountOut", amountOut);

        IERC20(address(proxysETH)).approve(address(swapRouter), 10 ether);
        ISwapRouter.ExactOutputSingleParams memory outputParams = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: address(proxysETH),
                tokenOut: address(proxysUSD),
                fee: fee,
                recipient: owner,
                deadline: block.timestamp + 10 minutes,
                amountOut: 0.099 ether,
                amountInMaximum: 10 ether,
                sqrtPriceLimitX96: 0
            });
        uint256 amountIn = swapRouter.exactOutputSingle(outputParams);
        console.log("amountIn", amountIn);

        vm.stopPrank();
    }

    function testOnlyBurner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        smx.burn();
        vm.stopPrank();

        vm.startPrank(owner);
        smx.grantRole(keccak256("BURNER_ROLE"), user1);
        vm.stopPrank();

        vm.startPrank(user1);
        assertEq(smx.balanceOf(reserveAddr), 200000 ether);
        smx.burn();
        assertEq(smx.balanceOf(reserveAddr), 100000 ether);
        vm.stopPrank();
    }

    function testTradeSynths() public {
        vm.startPrank(user1);

        synthetix.issueMaxSynths();

        // IERC20(address(proxysUSD)).approve(address(router), 50 ether);
        // address[] memory path = new address[](2);
        // path[0] = address(proxysUSD);
        // path[1] = address(proxysETH);
        // router.swapExactTokensForTokens(
        //     1 ether,
        //     0,
        //     path,
        //     user1,
        //     block.timestamp + 10 minutes
        // );

        address[] memory path = new address[](2);
        path[0] = address(proxysUSD);
        path[1] = address(proxysETH);
        bytes memory _data = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            // "swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)",
            1 ether,
            0,
            path,
            address(synthSwap),
            block.timestamp + 10 minutes
        );

        console.log();
        console.log("--- BEFORE ---");
        console.log(
            "sUSD balanceOf(user1)",
            IERC20(address(proxysUSD)).balanceOf(user1)
        );
        console.log(
            "sETH balanceOf(user1)",
            IERC20(address(proxysETH)).balanceOf(user1)
        );

        IERC20(address(proxysUSD)).approve(address(synthSwap), 10 ether);
        synthSwap.uniswapSwapInto("sETH", address(proxysUSD), 10 ether, _data);

        console.log();
        console.log("--- AFTER ---");
        console.log(
            "sUSD balanceOf(user1)",
            IERC20(address(proxysUSD)).balanceOf(user1)
        );
        console.log(
            "sETH balanceOf(user1)",
            IERC20(address(proxysETH)).balanceOf(user1)
        );

        vm.stopPrank();
    }

    //  function testTradeSynths() public {
    //     vm.startPrank(user4);
    //     IERC20(address(proxySNX)).transfer(address(tradingRewards), 250 ether);
    //     IERC20(address(proxySNX)).transfer(
    //         address(rewardsDistribution),
    //         250 ether
    //     );
    //     vm.stopPrank();

    //     vm.startPrank(user5);
    //     synthetix.issueMaxSynths();

    //     address[] memory path = new address[](2);
    //     path[0] = address(proxysUSD);
    //     path[1] = address(proxysETH);
    //     bytes memory _data = abi.encodeWithSignature(
    //         "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
    //         1 ether,
    //         0,
    //         path,
    //         address(synthSwap),
    //         block.timestamp + 10 minutes
    //     );

    //     IERC20(address(proxysUSD)).approve(address(synthSwap), 10 ether);
    //     synthSwap.uniswapSwapInto("sETH", address(proxysUSD), 10 ether, _data);

    //     // synthetix.exchange("sUSD", 100 ether, "sETH");

    //     tradingRewards.closeCurrentPeriodWithRewards(
    //         tradingRewards.getPeriodRecordedFees(0)
    //     );

    //     // assertEq(tradingRewards.getPeriodAvailableRewards(0), 1001);
    //     // assertEq(tradingRewards.getPeriodIsClaimable(0), true);
    //     // assertEq(tradingRewards.getPeriodRecordedFees(0), 1001);
    //     // assertEq(tradingRewards.getAvailableRewards(), 1001);
    //     // assertEq(
    //     //     tradingRewards.getAvailableRewardsForAccountForPeriod(user5, 0),
    //     //     1001
    //     // );

    //     console.log(tradingRewards.getPeriodRecordedFees(0));
    //     console.log(tradingRewards.getPeriodIsClaimable(0));
    //     console.log(tradingRewards.getAvailableRewards());
    //     console.log(
    //         "getPeriodAvailableRewards(0)",
    //         tradingRewards.getPeriodAvailableRewards(0)
    //     );
    //     console.log();
    //     console.log(
    //         "getAvailableRewardsForAccountForPeriod(user5, 0)",
    //         tradingRewards.getAvailableRewardsForAccountForPeriod(user5, 0)
    //     );
    //     console.log(
    //         "getAvailableRewardsForAccountForPeriod(owner, 0)",
    //         tradingRewards.getAvailableRewardsForAccountForPeriod(owner, 0)
    //     );

    //     vm.stopPrank();
    // }

    function testSwap() public {
        vm.startPrank(user1);

        console.log("BEFORE");
        console.log("SMX", smx.balanceOf(user1));
        console.log("WETH", IERC20(WETH).balanceOf(user1));

        _swap(WETH, address(smx), 10 ether, user1);

        console.log("AFTER");
        console.log("SMX", smx.balanceOf(user1));
        console.log("WETH", IERC20(WETH).balanceOf(user1));

        vm.stopPrank();
    }

    function testTax() public {
        vm.startPrank(user1);

        _swap(WETH, address(smx), 10 ether, user1); // BUY
        _swap(address(smx), WETH, 5 ether, user1); // SELL

        console.log();
        console.log("threshold\n", smx.threshold());
        console.log("currentFeeAmount\n", smx.currentFeeAmount());
        console.log("balanceOf smx\n", smx.balanceOf(address(smx)));

        smx.transfer(user3, 1 ether);

        vm.stopPrank();

        console.log();
        console.log("BALANCE WETH");
        console.log("balanceOf smx\n", smx.balanceOf(address(smx)));
        console.log("user2 balance\n", IERC20(WETH).balanceOf(user2));
    }

    function testBlacklist() public {
        vm.startPrank(owner);
        smx.updateBlacklist(user1, true);
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectRevert("Address is blacklisted");
        smx.transfer(user3, 1 ether);
        vm.stopPrank();
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
