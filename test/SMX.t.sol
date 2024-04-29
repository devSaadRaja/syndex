// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Setup} from "./Setup.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {ISwapRouter} from "../src/contracts/SMX/interfaces/ISwapRouter.sol";
import {IUniswapV3Factory} from "../src/contracts/SMX/interfaces/IUniswapV3Factory.sol";
import {INonfungiblePositionManager} from "../src/contracts/SMX/interfaces/INonfungiblePositionManager.sol";

import {SMX} from "../src/contracts/SMX/SMX.sol";
import {Staking} from "../src/contracts/staking/Staking.sol";
import {SynthSwap} from "../src/contracts/SMX/Synthswap.sol";
import {RewardEscrow} from "../src/contracts/SMX/RewardEscrow.sol";
import {vSMXRedeemer} from "../src/contracts/SMX/vSMXRedeemer.sol";
import {SupplySchedule} from "../src/contracts/SMX/SupplySchedule.sol";
import {MultipleMerkleDistributor} from "../src/contracts/SMX/MultipleMerkleDistributor.sol";

contract SMXTest is Setup {
    address public treasury = vm.addr(7);
    address public reserveAddr = vm.addr(8);

    // ? OPTIMISM DEPLOYMENTS --
    IUniswapV3Factory v3factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    IUniswapV2Router02 swapRouter =
        IUniswapV2Router02(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    SynthSwap public synthSwap;

    SMX public smx;
    Staking public staking;
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

        // v3factory.createPool(address(proxysUSD), address(proxysETH), 3000);
        // address p = v3factory.getPool(
        //     address(proxysUSD),
        //     address(proxysETH),
        //     3000
        // );
        // console.log(p);

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

        synthSwap = new SynthSwap(
            address(synthsUSD),
            address(router),
            address(addressResolver),
            owner, // volumeRewards
            treasury
        );

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

        factory.createPair(address(smx), WETH);
        address pair = factory.getPair(address(smx), WETH);

        // ? SETUP
        smx.setTrade(true);
        smx.setDeploy(true);
        smx.setPool(pair, true);
        smx.setFeeTaker(user2, 100);
        smx.setRouter(address(router));
        smx.setReserveAddress(reserveAddr);
        smx.setRewardAddress(address(WETH));
        smx.setExcludeFromFee(address(smx), true);

        smx.transfer(reserveAddr, 200000 ether);
        smx.transfer(address(staking), 100 ether);

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
