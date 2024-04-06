// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";
import {Utils} from "./Utils.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

// import {TokenState} from "../src/contracts/TokenState.sol";
// import {ProxyERC20} from "../src/contracts/ProxyERC20.sol";
// import {AddressResolver} from "../src/contracts/AddressResolver.sol";
// import {MultiCollateralSynth} from "../src/contracts/MultiCollateralSynth.sol";

import {SMX} from "../src/contracts/SMX/SMX.sol";
import {Staking} from "../src/contracts/staking/Staking.sol";
import {SynthSwap} from "../src/contracts/SMX/Synthswap.sol";
import {RewardEscrow} from "../src/contracts/SMX/RewardEscrow.sol";
import {vSMXRedeemer} from "../src/contracts/SMX/vSMXRedeemer.sol";
import {SupplySchedule} from "../src/contracts/SMX/SupplySchedule.sol";
import {MultipleMerkleDistributor} from "../src/contracts/SMX/MultipleMerkleDistributor.sol";

contract SMXTest is Setup {
    // address public deployerOnETH = 0xEb3107117FEAd7de89Cd14D463D340A2E6917769;
    address public treasury = vm.addr(5);

    // // ? OPTIMISM DEPLOYMENTS ---

    // address WETH = 0x4200000000000000000000000000000000000006;
    // IUniswapV2Factory factory =
    //     IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    // IUniswapV2Router02 router =
    //     IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    SynthSwap public synthSwap;
    // ProxyERC20 public proxysUSD;
    // TokenState public tokenStatesUSD;
    // MultiCollateralSynth public synthsUSD;
    // AddressResolver public addressResolver;

    SMX public smx;
    Staking public staking;
    RewardEscrow public rewardEscrow2;
    vSMXRedeemer public vSmxRedeemer;
    SupplySchedule public supplySchedule2;
    MultipleMerkleDistributor public multipleMerkleDistributor;

    function setUp() public override {
        super.setUp();

        // vm.startPrank(deployerOnETH);
        // proxySNX.transfer(owner, 100 ether);
        // proxySNX.transfer(user1, 100 ether);
        // vm.stopPrank();

        vm.startPrank(address(issuer));
        synthsUSD.issue(owner, 1000 ether);
        synthsUSD.issue(user1, 1000 ether);
        vm.stopPrank();

        vm.startPrank(owner);

        synthetix.exchange("sUSD", 500 ether, "sETH");

        _passTime(400);

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

        // proxysUSD = new ProxyERC20(owner);
        // addressResolver = new AddressResolver(owner);
        // tokenStatesUSD = new TokenState(owner, address(synthsUSD));
        // synthsUSD = new MultiCollateralSynth(
        //     payable(address(proxysUSD)),
        //     address(tokenStatesUSD),
        //     "SynthsUSD",
        //     "sUSD",
        //     owner,
        //     "sUSD",
        //     0,
        //     address(addressResolver)
        // );
        // synthSwap = new SynthSwap(
        //     address(synthsUSD),
        //     address(router),
        //     address(addressResolver),
        //     owner, // volumeRewards
        //     treasury
        // );

        // proxysUSD.setTarget(address(synthsUSD));
        // tokenStatesUSD.setAssociatedContract(address(synthsUSD));

        smx = new SMX("SMX", "SMX", owner, 100_000_000 ether);
        staking = new Staking(address(smx), address(smx));
        supplySchedule2 = new SupplySchedule(owner, treasury);
        // vSmxRedeemer = new vSMXRedeemer(address(smx), address(smx));
        rewardEscrow2 = new RewardEscrow(owner, address(smx));
        multipleMerkleDistributor = new MultipleMerkleDistributor(
            owner,
            address(smx),
            address(rewardEscrow2)
        );

        deal(address(smx), owner, 500 ether);
        deal(address(smx), user1, 500 ether);

        factory.createPair(address(smx), WETH);
        address pair = factory.getPair(address(smx), WETH);

        // ? SETUP
        smx.setTrade(true);
        smx.setDeploy(true);
        smx.setPool(pair, true);
        smx.setFeeTaker(user2, 100);
        smx.setRouter(address(router));
        smx.setRewardAddress(address(WETH));
        smx.setExcludeFromFee(address(smx), true);

        smx.transfer(address(staking), 100 * 10 ** 18);

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
        supplySchedule2.setStakingRewards(address(staking));
        supplySchedule2.setTradingRewards(address(multipleMerkleDistributor));

        // multipleMerkleDistributor.setMerkleRootForEpoch();

        vm.stopPrank();
    }

    function testTradeSynths() public {
        vm.startPrank(user1);

        synthetix.issueMaxSynths();

        IERC20(address(proxysUSD)).approve(address(router), 50 ether);
        address[] memory path = new address[](2);
        path[0] = address(proxysUSD);
        path[1] = address(proxysETH);
        router.swapExactTokensForTokens(
            1 ether,
            0,
            path,
            user1,
            block.timestamp + 10 minutes
        );

        // IERC20(address(proxysUSD)).approve(address(synthSwap), 50 ether);
        // synthSwap.uniswapSwapInto(
        //     bytes32("sETH"), // "sETH", // bytes32(abi.encodePacked("sETH"))
        //     address(proxysUSD),
        //     50 ether,
        //     _data
        // );

        vm.stopPrank();
    }

    function testSwap() public {
        vm.startPrank(user1);

        console.log("BEFORE");
        console.log("SNX", smx.balanceOf(user1));
        console.log("WETH", IERC20(WETH).balanceOf(user1));

        _swap(WETH, address(smx), 10 ether, user1);

        console.log("AFTER");
        console.log("SNX", smx.balanceOf(user1));
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
