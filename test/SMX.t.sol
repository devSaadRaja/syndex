// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {Token} from "../src/contracts/test/Token.sol";
import {SynthSwap} from "../src/contracts/Synthswap.sol";

import {IFeePool} from "../src/interfaces/IFeePool.sol";
import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "../src/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "../src/interfaces/IUniswapV3Factory.sol";
import {IAggregationRouterV4} from "../src/interfaces/IAggregationRouterV4.sol";
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

import "../src/libraries/SafeCast.sol";
import "../src/libraries/SafeDecimalMath.sol";

contract SMXTest is Setup {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    address public constant FEE_ADDRESS =
        0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;

    IUniswapV3Factory v3factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    INonfungiblePositionManager nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    IUniswapV3Pool v3Pool;

    SynthSwap public synthSwap2;

    function setUp() public override {
        super.setUp();

        vm.startPrank(user7);
        syndex.createMaxSynths();
        vm.stopPrank();

        vm.startPrank(user8);
        syndex.createMaxSynths();
        vm.stopPrank();

        vm.startPrank(user7);

        token = new Token("Token", "TKN", user7, 1_000_000 ether);
        synthSwap2 = new SynthSwap(
            address(proxycfUSD),
            address(swapRouter), // routerV4, aggregationRouterV4
            address(addressResolver),
            user7,
            treasury
        );

        token.transfer(user5, 1000 ether);
        token.transfer(user6, 1000 ether);
        token.transfer(user8, 1000 ether);

        // ! MAKE POOL ---

        v3factory.createPool(address(proxycfUSD), address(token), 3000); // take care of sequence of tokens
        address pool = v3factory.getPool(
            address(proxycfUSD),
            address(token),
            3000
        );

        v3Pool = IUniswapV3Pool(pool);
        v3Pool.initialize(79228162514264337593543950336);

        // ! ADD LIQUIDITY ---

        IERC20(address(proxycfUSD)).approve(
            address(nonfungiblePositionManager),
            50 ether
        );
        IERC20(address(token)).approve(
            address(nonfungiblePositionManager),
            50 ether
        );

        // int24 tickSpacing = v3Pool.tickSpacing();
        // uint128 liquidity = v3Pool.liquidity();
        uint24 fee = v3Pool.fee();
        // (
        //     uint160 sqrtPriceX96,
        //     int24 tick,
        //     uint16 observationIndex,
        //     uint16 observationCardinality,
        //     uint16 observationCardinalityNext,
        //     uint8 feeProtocol,
        //     bool unlocked
        // ) = v3Pool.slot0();

        // console.log("liquidity BEFORE", liquidity);
        // console.log("tickSpacing", uint24(tickSpacing));
        // console.log("fee", fee);
        // console.log("sqrtPriceX96", sqrtPriceX96);
        // console.log("tick", uint24(tick));
        // console.log("observationIndex", uint16(observationIndex));
        // console.log("observationCardinality", uint16(observationCardinality));
        // console.log(
        //     "observationCardinalityNext",
        //     uint16(observationCardinalityNext)
        // );
        // console.log("feeProtocol", uint16(feeProtocol));
        // console.log("unlocked", unlocked);

        // tickLower = nearestUsableTick(tick, tickSpacing) - tickSpacing * 2;
        // tickUpper = nearestUsableTick(tick, tickSpacing) + tickSpacing * 2;

        address token0 = address(token) < address(proxycfUSD)
            ? address(token)
            : address(proxycfUSD);
        address token1 = token0 == address(token)
            ? address(proxycfUSD)
            : address(token);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: fee,
                tickLower: -120,
                tickUpper: 120,
                amount0Desired: 50 ether,
                amount1Desired: 50 ether,
                amount0Min: 0,
                amount1Min: 0,
                recipient: user7,
                deadline: block.timestamp + 10 minutes
            });

        nonfungiblePositionManager.mint(params);

        vm.stopPrank();

        // (uint amountReceived, , ) = exchanger.getAmountsForExchange(
        //     1 ether,
        //     "cfUSD",
        //     "cfETH"
        // );
        // console.log(amountReceived, "<<< amountReceived");
    }

    function testCRatio() public {
        vm.startPrank(user7);

        uint collateral = syndex.collateral(user7);
        assertEq(collateral, 5000 ether);

        // if (collateral == 0) return 0;

        uint currentDebt = syndex.debtBalanceOf(user7, "SFCX");
        assertEq(currentDebt, 1650 ether);

        // uint calculatedCRatio = currentDebt.divideDecimalRound(collateral);
        // assertEq(calculatedCRatio, 0.33 ether);
        // uint currentDebtCRatio = 300 ether / calculatedCRatio;
        // assertEq(currentDebtCRatio, 909);

        uint oldCRatio = (collateral.divideDecimalRound(currentDebt)) * 100;
        assertGt(oldCRatio, 303 ether);

        // uint syndexCRatio = syndex.collateralisationRatio(user7);
        // assertEq(syndexCRatio, 0.33 ether);

        uint newDebt = currentDebt + 1 ether;
        assertEq(newDebt, 1651 ether);

        // uint newCalculatedCRatio = newDebt.divideDecimalRound(collateral);
        // assertEq(newCalculatedCRatio, 0.3302 ether);
        // uint newDebtCRatio = 300 ether / newCalculatedCRatio;
        // assertEq(newDebtCRatio, 908);

        uint newCRatio = (collateral.divideDecimalRound(newDebt)) * 100;
        assertLt(newCRatio, 303 ether);

        vm.stopPrank();
    }

    function testRouterV4() public {
        vm.startPrank(user7);

        // ! SWAP ---

        // ? uniswapSwapInto

        ISwapRouter.ExactInputSingleParams memory inputParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(token),
                tokenOut: address(proxycfUSD),
                fee: v3Pool.fee(),
                recipient: address(synthSwap2),
                deadline: block.timestamp + 10 minutes,
                amountIn: 1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        bytes memory _data = abi.encodeWithSelector(
            ISwapRouter.exactInputSingle.selector,
            inputParams
        );

        // IAggregationRouterV4.SwapDescription memory desc = IAggregationRouterV4
        //     .SwapDescription({
        //         srcToken: address(proxycfUSD),
        //         dstToken: address(token),
        //         srcReceiver: payable(user7),
        //         dstReceiver: payable(user7),
        //         amount: 1 ether,
        //         minReturnAmount: 0.01 ether,
        //         flags: 1,
        //         permit: new bytes(0)
        //     });

        // bytes memory data = abi.encodeWithSelector(
        //     IAggregationRouterV4.swap.selector,
        //     // IAggregationExecutor(address(swapRouter)),
        //     swapRouter,
        //     desc,
        //     _data
        // );

        console.log("BEFORE token\n", token.balanceOf(user7));
        console.log("BEFORE proxycfETH\n", proxycfETH.balanceOf(user7));

        IERC20(address(token)).approve(address(synthSwap2), 2 ether);
        synthSwap2.uniswapSwapInto("cfETH", address(token), 1 ether, _data);
        // // IERC20(address(proxycfUSD)).approve(address(synthSwap2), 10 ether);
        // // synthSwap2.uniswapSwapInto("cfETH", address(proxycfUSD), 10 ether, data);

        console.log("AFTER uniswapSwapInto token\n", token.balanceOf(user7));
        console.log(
            "AFTER uniswapSwapInto proxycfETH\n",
            proxycfETH.balanceOf(user7)
        );

        // ? uniswapSwapOutOf

        ISwapRouter.ExactInputSingleParams memory outParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(proxycfUSD),
                tokenOut: address(token),
                fee: v3Pool.fee(),
                recipient: address(synthSwap2),
                deadline: block.timestamp + 10 minutes,
                amountIn: 0.5 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        bytes memory _dataOut = abi.encodeWithSelector(
            ISwapRouter.exactInputSingle.selector,
            outParams
        );

        IERC20(address(proxycfETH)).approve(address(synthSwap2), 2 ether);
        synthSwap2.uniswapSwapOutOf(
            "cfETH",
            address(token),
            0.8 ether,
            2 ether,
            _dataOut
        );

        console.log("AFTER uniswapSwapOutOf token\n", token.balanceOf(user7));
        console.log(
            "AFTER uniswapSwapOutOf proxycfETH\n",
            proxycfETH.balanceOf(user7)
        );

        ISwapRouter.ExactInputSingleParams memory paramsss = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(token),
                tokenOut: address(proxycfUSD),
                fee: v3Pool.fee(),
                recipient: address(synthSwap2),
                deadline: block.timestamp + 10 minutes,
                amountIn: 1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        bytes memory _dataaa = abi.encodeWithSelector(
            ISwapRouter.exactInputSingle.selector,
            paramsss
        );

        console.log("BEFORE token\n", token.balanceOf(user7));
        console.log("BEFORE proxycfUSD\n", proxycfUSD.balanceOf(user7));

        IERC20(address(token)).approve(address(synthSwap2), 2 ether);
        synthSwap2.uniswapSwapInto("cfUSD", address(token), 1 ether, _dataaa);

        console.log("AFTER token\n", token.balanceOf(user7));
        console.log("AFTER proxycfUSD\n", proxycfUSD.balanceOf(user7));

        vm.stopPrank();
    }

    function testUniswapV3() public {
        vm.startPrank(user7);

        // ! SWAP ---

        IERC20(address(proxycfUSD)).approve(address(swapRouter), 10 ether);
        ISwapRouter.ExactInputSingleParams memory inputParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(proxycfUSD),
                tokenOut: address(token),
                fee: v3Pool.fee(),
                recipient: user7,
                deadline: block.timestamp + 10 minutes,
                amountIn: 1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter.exactInputSingle(inputParams);
        assertLt(amountOut, 1 ether);

        IERC20(address(token)).approve(address(swapRouter), 10 ether);
        ISwapRouter.ExactOutputSingleParams memory outputParams = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: address(token),
                tokenOut: address(proxycfUSD),
                fee: v3Pool.fee(),
                recipient: user7,
                deadline: block.timestamp + 10 minutes,
                amountOut: 1 ether,
                amountInMaximum: 10 ether,
                sqrtPriceLimitX96: 0
            });
        uint256 amountIn = swapRouter.exactOutputSingle(outputParams);
        assertGt(amountIn, 1 ether);

        vm.stopPrank();
    }

    function testExchange() public {
        vm.startPrank(user7);
        proxycfUSD.transfer(user6, 100 ether);
        vm.stopPrank();

        assertEq(proxycfUSD.balanceOf(user6), 100 ether);
        assertEq(proxycfETH.balanceOf(user6), 0);

        vm.startPrank(user6);
        syndex.executeExchange("cfUSD", 50 ether, "cfETH");
        vm.stopPrank();

        assertEq(proxycfUSD.balanceOf(user6), 50 ether);
        assertEq(proxycfETH.balanceOf(user6), 49.9 ether);
    }

    function testClaimTimeEnded() public {
        vm.startPrank(user7);
        proxycfUSD.transfer(user6, 100 ether);
        syndex.executeExchange("cfUSD", 50 ether, "cfETH");
        vm.stopPrank();

        vm.startPrank(user6);
        syndex.executeExchange("cfUSD", 50 ether, "cfETH");
        vm.stopPrank();

        vm.startPrank(user8);
        syndex.executeExchange("cfUSD", 50 ether, "cfETH");
        vm.stopPrank();

        _passTime(7 days);

        vm.startPrank(owner);
        feePool.closeCurrentFeePeriod();
        vm.stopPrank();

        (uint256 totalFees, uint256 totalRewards) = feePool.feesAvailable(
            user7
        );
        assertEq(totalFees, 0.15 ether);
        assertEq(totalRewards, 0);

        (totalFees, totalRewards) = feePool.feesAvailable(user8);
        assertEq(totalFees, 0.15 ether);
        assertEq(totalRewards, 0);

        _passTime(7 days);

        vm.startPrank(owner);
        feePool.closeCurrentFeePeriod();
        vm.stopPrank();

        (totalFees, totalRewards) = feePool.feesAvailable(user7);
        assertEq(totalFees, 0);
        assertEq(totalRewards, 0);

        (totalFees, totalRewards) = feePool.feesAvailable(user8);
        assertEq(totalFees, 0);
        assertEq(totalRewards, 0);
    }

    function testStakersTradeFee() public {
        vm.startPrank(user7);
        proxycfUSD.transfer(user6, 100 ether);
        syndex.executeExchange("cfUSD", 50 ether, "cfETH");
        vm.stopPrank();

        vm.startPrank(user6);
        syndex.executeExchange("cfUSD", 50 ether, "cfETH");
        vm.stopPrank();

        vm.startPrank(user8);
        syndex.executeExchange("cfUSD", 50 ether, "cfETH");
        vm.stopPrank();

        // feePool.isFeesClaimable(user8),

        assertEq(IERC20(address(proxycfUSD)).balanceOf(FEE_ADDRESS), 0.3 ether);
        assertEq(
            IERC20(address(proxycfUSD)).balanceOf(address(user7)),
            1450 ether
        );
        assertEq(syndexDebtShare.balanceOf(address(user7)), 1650 ether);

        _passTime(7 days);

        vm.startPrank(owner);
        debtCache.takeDebtSnapshot();

        syndexDebtShare.addAuthorizedToSnapshot(owner);
        syndexDebtShare.takeSnapshot(2);

        (bool close, ) = payable(proxyFeePool).call(
            abi.encodeWithSignature("closeCurrentFeePeriod()")
        );
        require(close, "Transaction Failed!");
        vm.stopPrank();

        assertEq(IERC20(address(proxycfUSD)).balanceOf(FEE_ADDRESS), 0);
        assertEq(
            IERC20(address(proxycfUSD)).balanceOf(address(user7)),
            1450 ether
        );
        assertEq(syndexDebtShare.balanceOf(address(user7)), 1650 ether);

        uint[2][2] memory results = feePool.feesByPeriod(user7);
        assertEq(results[0][0], 0);
        assertEq(results[1][0], 0.15 ether);

        (uint256 totalFees, ) = feePool.feesAvailable(user7);
        assertEq(totalFees, 0.15 ether);
        (totalFees, ) = feePool.feesAvailable(user8);
        assertEq(totalFees, 0.15 ether);

        vm.startPrank(user7);
        (bool claim, ) = payable(proxyFeePool).call(
            abi.encodeWithSignature("claimFees()")
        );
        require(claim, "Transaction Failed!");

        syndex.createMaxSynths();
        vm.stopPrank();

        assertEq(
            IERC20(address(proxycfUSD)).balanceOf(address(user7)),
            1450.15 ether
        );
        assertEq(
            syndexDebtShare.balanceOf(address(user7)),
            1650150013637603418493
        );

        (totalFees, ) = feePool.feesAvailable(user7);
        assertEq(totalFees, 0);
        (totalFees, ) = feePool.feesAvailable(user8);
        assertEq(totalFees, 0.15 ether);
    }

    function testTradersTradeFee() public {
        vm.startPrank(owner);
        IERC20(address(proxySFCX)).transfer(address(tradingRewards), 250 ether);
        vm.stopPrank();

        vm.startPrank(user7);
        syndex.executeExchange("cfUSD", 50 ether, "cfETH");
        vm.stopPrank();

        vm.startPrank(user8);
        syndex.executeExchange("cfUSD", 50 ether, "cfETH");
        vm.stopPrank();

        assertEq(IERC20(address(proxycfUSD)).balanceOf(FEE_ADDRESS), 0.2 ether);
        assertEq(
            IERC20(address(proxycfUSD)).balanceOf(address(user7)),
            1550 ether
        );
        assertEq(syndexDebtShare.balanceOf(address(user7)), 1650 ether);

        assertEq(IERC20(address(proxycfUSD)).balanceOf(FEE_ADDRESS), 0.2 ether);
        assertEq(
            IERC20(address(proxycfUSD)).balanceOf(address(user7)),
            1550 ether
        );
        assertEq(syndexDebtShare.balanceOf(address(user7)), 1650 ether);

        assertEq(
            IERC20(address(proxycfUSD)).balanceOf(address(user7)),
            1550 ether
        );
        assertEq(syndexDebtShare.balanceOf(address(user7)), 1650 ether);

        vm.startPrank(user5);
        tradingRewards.closeCurrentPeriodWithRewards(
            tradingRewards.getPeriodRecordedFees(0)
        );
        vm.stopPrank();

        assertEq(tradingRewards.isPeriodClaimable(0), true);
        assertEq(tradingRewards.getAvailableRewards(), 0.2 ether);
        assertEq(tradingRewards.getPeriodRecordedFees(0), 0.2 ether);
        assertEq(tradingRewards.getPeriodAvailableRewards(0), 0.2 ether);
        assertEq(
            tradingRewards.getAvailableRewardsForAccountForPeriod(user7, 0),
            0.1 ether
        );

        uint256 amountBefore = IERC20(address(proxySFCX)).balanceOf(user7);
        uint256 rewardAmount = tradingRewards
            .getAvailableRewardsForAccountForPeriod(user7, 0);

        vm.startPrank(user7);
        tradingRewards.redeemRewardsForPeriod(0);
        vm.stopPrank();

        assertEq(
            IERC20(address(proxySFCX)).balanceOf(user7),
            amountBefore + rewardAmount
        );

        assertEq(syndexDebtShare.totalSupply(), 3300 ether);
        assertEq(syndexDebtShare.balanceOf(address(user7)), 1650 ether);
        assertEq(syndexDebtShare.balanceOf(address(user8)), 1650 ether);

        assertEq(tradingRewards.getAvailableRewards(), 0.1 ether);
        assertEq(tradingRewards.getPeriodRecordedFees(0), 0.2 ether);
        assertEq(tradingRewards.getPeriodAvailableRewards(0), 0.1 ether);
        assertEq(
            tradingRewards.getAvailableRewardsForAccountForPeriod(user7, 0),
            0
        );
        assertEq(
            tradingRewards.getAvailableRewardsForAccountForPeriod(user8, 0),
            0.1 ether
        );
    }

    function testMultiCollateralReturns() public {
        vm.startPrank(user6);

        // ! BEFORE !

        assertEq(address(user6).balance, 100 ether);
        assertEq(address(collateralETH).balance, 0);
        assertEq(IERC20(address(token)).balanceOf(user6), 1000 ether);
        assertEq(IERC20(address(proxySFCX)).balanceOf(user6), 1000 ether);
        assertEq(IERC20(address(proxycfUSD)).balanceOf(user6), 0);
        assertEq(IERC20(address(proxycfETH)).balanceOf(user6), 0);

        assertEq(syndex.transferableSynDex(user6), 1000 ether);
        assertEq(syndexDebtShare.totalSupply(), 3300 ether);
        assertEq(syndexDebtShare.balanceOf(user6), 0);
        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 3300 ether);

        assertEq(collateralManager.state().totalLoans(), 0);
        (uint long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 0);
        (uint cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 0);

        // ! CREATE SYNTHS !

        syndex.createSynths(1 ether);

        uint256 id = collateralETH.open{value: 1.5 ether}(1 ether, "cfUSD");

        assertEq(address(user6).balance, 98.5 ether);
        assertEq(address(collateralETH).balance, 1.5 ether);
        assertEq(IERC20(address(token)).balanceOf(user6), 1000 ether);
        assertEq(IERC20(address(proxySFCX)).balanceOf(user6), 1000 ether);
        assertEq(IERC20(address(proxycfUSD)).balanceOf(user6), 2 ether);
        assertEq(IERC20(address(proxycfETH)).balanceOf(user6), 0);

        assertLt(syndex.transferableSynDex(user6), 1000 ether);
        assertEq(syndexDebtShare.totalSupply(), 3301 ether);
        assertEq(syndexDebtShare.balanceOf(user6), 1 ether);
        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 3301 ether);

        assertEq(collateralManager.state().totalLoans(), 1);
        (long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 1 ether);
        (cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 1 ether);

        // ! SYNTH SWAP !

        ISwapRouter.ExactInputSingleParams memory inputParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(token),
                tokenOut: address(proxycfUSD),
                fee: v3Pool.fee(),
                recipient: address(synthSwap),
                deadline: block.timestamp + 10 minutes,
                amountIn: 1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        bytes memory _data = abi.encodeWithSelector(
            ISwapRouter.exactInputSingle.selector,
            inputParams
        );

        IERC20(address(token)).approve(address(synthSwap), 1 ether);
        synthSwap.uniswapSwapInto("cfETH", address(token), 1 ether, _data);

        assertEq(address(user6).balance, 98.5 ether);
        assertEq(address(collateralETH).balance, 1.5 ether);
        assertEq(IERC20(address(token)).balanceOf(user6), 999 ether);
        assertEq(IERC20(address(proxySFCX)).balanceOf(user6), 1000 ether);
        assertEq(IERC20(address(proxycfUSD)).balanceOf(user6), 2 ether);
        assertGt(IERC20(address(proxycfETH)).balanceOf(user6), 0);

        assertLt(syndex.transferableSynDex(user6), 1000 ether);
        assertEq(syndexDebtShare.totalSupply(), 3301 ether);
        assertEq(syndexDebtShare.balanceOf(user6), 1 ether);
        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 3301 ether);

        assertEq(collateralManager.state().totalLoans(), 1);
        (long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 1 ether);
        (cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 1 ether);

        // ! AFTER DAYS PAST !

        _passTime(7 days);

        assertEq(address(user6).balance, 98.5 ether);
        assertEq(address(collateralETH).balance, 1.5 ether);
        assertEq(IERC20(address(token)).balanceOf(user6), 999 ether);
        assertEq(IERC20(address(proxySFCX)).balanceOf(user6), 1000 ether);
        assertEq(IERC20(address(proxycfUSD)).balanceOf(user6), 2 ether);
        assertGt(IERC20(address(proxycfETH)).balanceOf(user6), 0);

        assertLt(syndex.transferableSynDex(user6), 1000 ether);
        assertEq(syndexDebtShare.totalSupply(), 3301 ether);
        assertEq(syndexDebtShare.balanceOf(user6), 1 ether);
        assertEq(syndexDebtShare.calculateTotalSupplyForPeriod(1), 3301 ether);

        assertEq(collateralManager.state().totalLoans(), 1);
        (long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 1 ether);
        (cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 1 ether);

        // ! AFTER SYNTH BURN !

        syndex.burnSynths(1 ether);
        // syndex.burnSynthsToTarget();

        // collateralETH.close(id);
        // collateralETH.claim(1.5 ether);

        assertEq(address(user6).balance, 98.5 ether);
        assertEq(address(collateralETH).balance, 1.5 ether);
        assertEq(IERC20(address(token)).balanceOf(user6), 999 ether);
        assertEq(IERC20(address(proxySFCX)).balanceOf(user6), 1000 ether);
        assertEq(IERC20(address(proxycfUSD)).balanceOf(user6), 1 ether);
        assertGt(IERC20(address(proxycfETH)).balanceOf(user6), 0);

        assertLt(syndex.transferableSynDex(user6), 1000 ether);
        assertLt(syndexDebtShare.totalSupply(), 33000004 ether);
        assertEq(syndexDebtShare.balanceOf(user6), 302846759539673);
        assertLt(
            syndexDebtShare.calculateTotalSupplyForPeriod(1),
            33000004 ether
        );

        assertEq(collateralManager.state().totalLoans(), 1);
        (long, ) = collateralManager.state().totalIssuedSynths("cfUSD");
        assertEq(long, 1 ether);
        (cfusdValue, ) = collateralManager.totalLongAndShort();
        assertEq(cfusdValue, 1 ether);

        vm.stopPrank();
    }

    function testSFCXBlacklist() public {
        vm.startPrank(owner);
        syndex.updateBlacklist(user1, true);
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectRevert("Address is blacklisted");
        proxySFCX.transfer(reserveAddr, 1 ether);
        vm.stopPrank();
    }

    function testSFCXOnlyBurner() public {
        vm.startPrank(user8);
        vm.expectRevert();
        syndex.burn();
        vm.stopPrank();

        vm.startPrank(owner);
        syndex.grantRole(keccak256("BURNER_ROLE"), user8);
        vm.stopPrank();

        vm.startPrank(user8);
        assertEq(proxySFCX.balanceOf(reserveAddr), 200000 ether);
        syndex.burn();
        assertEq(proxySFCX.balanceOf(reserveAddr), 100000 ether);
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
