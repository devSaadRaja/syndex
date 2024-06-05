// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {Token} from "../src/contracts/test/Token.sol";

import {ISwapRouter} from "../src/contracts/SMX/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "../src/contracts/SMX/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "../src/contracts/SMX/interfaces/IUniswapV3Factory.sol";
import {IAggregationRouterV4} from "../src/contracts/SMX/interfaces/IAggregationRouterV4.sol";
import {INonfungiblePositionManager} from "../src/contracts/SMX/interfaces/INonfungiblePositionManager.sol";

import {RewardEscrow} from "../src/contracts/SMX/RewardEscrow.sol";
import {vSMXRedeemer} from "../src/contracts/SMX/vSMXRedeemer.sol";
import {SupplySchedule} from "../src/contracts/SMX/SupplySchedule.sol";
import {MultipleMerkleDistributor} from "../src/contracts/SMX/MultipleMerkleDistributor.sol";

import {SynthSwap} from "../src/contracts/SMX/Synthswap2.sol";
import {AggregationRouterV4} from "../src/contracts/SMX/AggregationRouterV4.sol";
import {IClipperExchangeInterface} from "../src/contracts/SMX/interfaces/IClipperExchangeInterface.sol";

contract SMXTest is Setup {
    IUniswapV3Factory v3factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    INonfungiblePositionManager nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    Token public token;
    IUniswapV3Pool v3Pool;

    RewardEscrow public rewardEscrow2;
    vSMXRedeemer public vSmxRedeemer;
    SupplySchedule public supplySchedule2;
    MultipleMerkleDistributor public multipleMerkleDistributor;

    SynthSwap public synthSwap2;
    AggregationRouterV4 public aggregationRouterV4;

    function setUp() public override {
        super.setUp();

        // vm.startPrank(address(issuer));
        // synthsUSD.issue(owner, 1000 ether);
        // synthsUSD.issue(user1, 1000 ether);
        // vm.stopPrank();

        vm.startPrank(owner);
        smx.transfer(user6, 1000 ether);
        smx.transfer(user7, 1000 ether);
        smx.transfer(user8, 1000 ether);
        vm.stopPrank();

        vm.startPrank(user7);
        synthetix.createMaxSynths();
        vm.stopPrank();

        vm.startPrank(user8);
        synthetix.createMaxSynths();
        vm.stopPrank();

        vm.startPrank(user7);

        synthetix.executeExchange("sUSD", 500 ether, "sETH");

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
            user7,
            block.timestamp + 10 minutes
        );

        supplySchedule2 = new SupplySchedule(user7, treasury);
        // vSmxRedeemer = new vSMXRedeemer(address(smx), address(smx));
        rewardEscrow2 = new RewardEscrow(user7, address(smx));
        multipleMerkleDistributor = new MultipleMerkleDistributor(
            user7,
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
            user7,
            block.timestamp + 10 minutes
        );

        supplySchedule2.setSMX(address(smx));
        supplySchedule2.setStakingRewards(address(stakingAddr));
        supplySchedule2.setTradingRewards(address(multipleMerkleDistributor));

        // multipleMerkleDistributor.setMerkleRootForEpoch();

        // IClipperExchangeInterface clipperExchangeInterface = IClipperExchangeInterface(
        //         0x655eDCE464CC797526600a462A8154650EEe4B77
        //     );

        // aggregationRouterV4 = new AggregationRouterV4(
        //     WETH,
        //     address(clipperExchangeInterface)
        // );

        token = new Token("Token", "TKN", user7, 1_000_000 ether);
        synthSwap2 = new SynthSwap(
            address(proxysUSD),
            address(swapRouter), // routerV4, aggregationRouterV4
            address(addressResolver),
            user7,
            treasury
        );

        token.transfer(user5, 1000 ether);
        token.transfer(user6, 1000 ether);
        token.transfer(user8, 1000 ether);

        // ! MAKE POOL ---

        v3factory.createPool(address(proxysUSD), address(token), 3000); // take care of sequence of tokens
        address pool = v3factory.getPool(
            address(proxysUSD),
            address(token),
            3000
        );

        v3Pool = IUniswapV3Pool(pool);
        v3Pool.initialize(79228162514264337593543950336);

        // ! ADD LIQUIDITY ---

        IERC20(address(proxysUSD)).approve(
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

        address token0 = address(token) < address(proxysUSD)
            ? address(token)
            : address(proxysUSD);
        address token1 = token0 == address(token)
            ? address(proxysUSD)
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
    }

    function testRouterV4() public {
        vm.startPrank(user7);

        // ! SWAP ---

        // ? uniswapSwapInto

        ISwapRouter.ExactInputSingleParams memory inputParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(token),
                tokenOut: address(proxysUSD),
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
        //         srcToken: address(proxysUSD),
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
        console.log("BEFORE proxysETH\n", proxysETH.balanceOf(user7));

        IERC20(address(token)).approve(address(synthSwap2), 2 ether);
        synthSwap2.uniswapSwapInto("sETH", address(token), 1 ether, _data);
        // // IERC20(address(proxysUSD)).approve(address(synthSwap2), 10 ether);
        // // synthSwap2.uniswapSwapInto("sETH", address(proxysUSD), 10 ether, data);

        console.log("AFTER uniswapSwapInto token\n", token.balanceOf(user7));
        console.log(
            "AFTER uniswapSwapInto proxysETH\n",
            proxysETH.balanceOf(user7)
        );

        // ? uniswapSwapOutOf

        ISwapRouter.ExactInputSingleParams memory outParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(proxysUSD),
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

        IERC20(address(proxysETH)).approve(address(synthSwap2), 2 ether);
        synthSwap2.uniswapSwapOutOf(
            "sETH",
            address(token),
            0.8 ether,
            2 ether,
            _dataOut
        );

        console.log("AFTER uniswapSwapOutOf token\n", token.balanceOf(user7));
        console.log(
            "AFTER uniswapSwapOutOf proxysETH\n",
            proxysETH.balanceOf(user7)
        );

        ISwapRouter.ExactInputSingleParams memory paramsss = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(token),
                tokenOut: address(proxysUSD),
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

        console.log();
        console.log();

        console.log("BEFORE token\n", token.balanceOf(user7));
        console.log("BEFORE proxysUSD\n", proxysUSD.balanceOf(user7));

        IERC20(address(token)).approve(address(synthSwap2), 2 ether);
        synthSwap2.uniswapSwapInto("sUSD", address(token), 1 ether, _dataaa);

        console.log("AFTER token\n", token.balanceOf(user7));
        console.log("AFTER proxysUSD\n", proxysUSD.balanceOf(user7));

        vm.stopPrank();
    }

    function testUniswapV3() public {
        vm.startPrank(user7);

        // ! SWAP ---

        IERC20(address(proxysUSD)).approve(address(swapRouter), 10 ether);
        ISwapRouter.ExactInputSingleParams memory inputParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(proxysUSD),
                tokenOut: address(token),
                fee: v3Pool.fee(),
                recipient: user7,
                deadline: block.timestamp + 10 minutes,
                amountIn: 1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter.exactInputSingle(inputParams);
        console.log("amountOut", amountOut);

        IERC20(address(token)).approve(address(swapRouter), 10 ether);
        ISwapRouter.ExactOutputSingleParams memory outputParams = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: address(token),
                tokenOut: address(proxysUSD),
                fee: v3Pool.fee(),
                recipient: user7,
                deadline: block.timestamp + 10 minutes,
                amountOut: 1 ether,
                amountInMaximum: 10 ether,
                sqrtPriceLimitX96: 0
            });
        uint256 amountIn = swapRouter.exactOutputSingle(outputParams);
        console.log("amountIn", amountIn);

        vm.stopPrank();
    }

    function testOnlyBurner() public {
        vm.startPrank(user8);
        vm.expectRevert();
        smx.burn();
        vm.stopPrank();

        vm.startPrank(owner);
        smx.grantRole(keccak256("BURNER_ROLE"), user8);
        vm.stopPrank();

        vm.startPrank(user8);
        assertEq(smx.balanceOf(reserveAddr), 200000 ether);
        smx.burn();
        assertEq(smx.balanceOf(reserveAddr), 100000 ether);
        vm.stopPrank();
    }

    function testTradeSynths() public {
        vm.startPrank(user4);
        IERC20(address(proxySNX)).transfer(address(tradingRewards), 250 ether);
        IERC20(address(proxySNX)).transfer(
            address(rewardsDistribution),
            250 ether
        );
        vm.stopPrank();

        vm.startPrank(user5);

        ISwapRouter.ExactInputSingleParams memory inputParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(token),
                tokenOut: address(proxysUSD),
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

        console.log();
        console.log("--- BEFORE ---");
        console.log(
            "token balanceOf(user5)",
            IERC20(address(token)).balanceOf(user5)
        );
        console.log(
            "sETH balanceOf(user5)",
            IERC20(address(proxysETH)).balanceOf(user5)
        );

        IERC20(address(token)).approve(address(synthSwap), 1 ether);
        synthSwap.uniswapSwapInto("sETH", address(token), 1 ether, _data);

        console.log();
        console.log("--- AFTER ---");
        console.log(
            "token balanceOf(user5)",
            IERC20(address(token)).balanceOf(user5)
        );
        console.log(
            "sETH balanceOf(user5)",
            IERC20(address(proxysETH)).balanceOf(user5)
        );

        tradingRewards.closeCurrentPeriodWithRewards(
            tradingRewards.getPeriodRecordedFees(0)
        );

        // assertEq(tradingRewards.getPeriodAvailableRewards(0), 1002);
        // assertEq(tradingRewards.isPeriodClaimable(0), true);
        // assertEq(tradingRewards.getPeriodRecordedFees(0), 1002);
        // assertEq(tradingRewards.getAvailableRewards(), 1002);
        // assertEq(
        //     tradingRewards.getAvailableRewardsForAccountForPeriod(user5, 0),
        //     1002
        // );

        // uint256 amountBefore = IERC20(address(proxySNX)).balanceOf(user5);
        // uint256 rewardAmount = tradingRewards
        //     .getAvailableRewardsForAccountForPeriod(user5, 0);

        // tradingRewards.redeemRewardsForPeriod(0);

        // assertEq(
        //     IERC20(address(proxySNX)).balanceOf(user5),
        //     amountBefore + rewardAmount
        // );

        console.log(tradingRewards.getPeriodRecordedFees(0));
        console.log(tradingRewards.isPeriodClaimable(0));
        console.log(tradingRewards.getAvailableRewards());
        console.log(
            "getPeriodAvailableRewards(0)",
            tradingRewards.getPeriodAvailableRewards(0)
        );
        console.log();
        console.log(
            "getAvailableRewardsForAccountForPeriod(user5, 0)",
            tradingRewards.getAvailableRewardsForAccountForPeriod(user5, 0)
        );
        console.log(
            "getAvailableRewardsForAccountForPeriod(user7, 0)",
            tradingRewards.getAvailableRewardsForAccountForPeriod(user7, 0)
        );

        vm.stopPrank();
    }

    function _consoleData(string memory str) internal view {
        console.log();
        console.log(str);
        console.log(
            IERC20(address(token)).balanceOf(user6),
            "<-- token balanceOf(user6)"
        );
        console.log(
            synthetix.transferableSynthetix(user6),
            "<-- synthetix transferableSynthetix(user6)"
        );
        console.log(
            IERC20(address(proxySNX)).balanceOf(user6),
            "<-- SNX balanceOf(user6)"
        );
        console.log(
            IERC20(address(proxysUSD)).balanceOf(user6),
            "<-- sUSD balanceOf(user6)"
        );
        console.log(
            IERC20(address(proxysETH)).balanceOf(user6),
            "<-- sETH balanceOf(user6)"
        );
        console.log(address(user6).balance, "<-- ETH balance address(user6)");
        console.log(
            address(collateralETH).balance,
            "<-- ETH balance address(collateralETH)"
        );
        console.log(
            IERC20(address(smx)).balanceOf(address(user6)),
            "<-- smx balanceOf(address(user6))"
        );
        console.log(
            IERC20(address(smx)).balanceOf(address(collateralErc20)),
            "<-- smx balanceOf(address(collateralErc20))"
        );
        console.log(
            synthetixDebtShare.totalSupply(),
            "<-- synthetixDebtShare.totalSupply()"
        );
        console.log(
            synthetixDebtShare.balanceOf(user6),
            "<-- synthetixDebtShare.balanceOf(user6)"
        );
        console.log(
            synthetixDebtShare.calculateTotalSupplyForPeriod(1),
            "<-- synthetixDebtShare.calculateTotalSupplyForPeriod(1)"
        );
        console.log(
            collateralManager.state().totalLoans(),
            "<-- collateralManager.state().totalLoans()"
        );

        (uint long, uint short) = collateralManager.state().totalIssuedSynths(
            "sUSD"
        );
        console.log(long, "<-- totalIssuedSynths(sUSD) long");
        console.log(short, "<-- totalIssuedSynths(sUSD) short");

        (uint susdValue, ) = collateralManager.totalLongAndShort();
        console.log(susdValue, "<-- susdValue");
    }

    function testMultiCollateralReturns() public {
        vm.startPrank(user6);

        _consoleData("--- BEFORE ---");

        synthetix.createSynths(1 ether);

        uint256 id = collateralETH.open{value: 1.5 ether}(1 ether, "sUSD");

        smx.approve(address(collateralErc20), 50 ether);
        uint256 idErc = collateralErc20.open(3 ether, 2 ether, "sUSD");

        _consoleData("--- AFTER SWAP ---");

        ISwapRouter.ExactInputSingleParams memory inputParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(token),
                tokenOut: address(proxysUSD),
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
        synthSwap.uniswapSwapInto("sETH", address(token), 1 ether, _data);

        _consoleData("--- AFTER SYNTH SWAP ---");

        synthetix.burnSynths(1 ether);
        // // synthetix.burnSynthsToTarget();

        collateralETH.close(id);
        collateralETH.claim(1.5 ether);

        collateralErc20.close(idErc);

        _consoleData("--- AFTER SYNTH BURN ---");

        vm.stopPrank();
    }

    function testSwap() public {
        vm.startPrank(user8);

        console.log("BEFORE");
        console.log("SMX", smx.balanceOf(user8));
        console.log("WETH", IERC20(WETH).balanceOf(user8));

        _swap(WETH, address(smx), 10 ether, user8);

        console.log("AFTER");
        console.log("SMX", smx.balanceOf(user8));
        console.log("WETH", IERC20(WETH).balanceOf(user8));

        vm.stopPrank();
    }

    function testTax() public {
        vm.startPrank(user8);

        _swap(WETH, address(smx), 10 ether, user8); // BUY
        _swap(address(smx), WETH, 5 ether, user8); // SELL

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
        smx.updateBlacklist(user8, true);
        vm.stopPrank();
        vm.startPrank(user8);
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
