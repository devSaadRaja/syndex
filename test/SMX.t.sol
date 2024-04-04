// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {SMX} from "../src/contracts/SMX/SMX.sol";
import {Staking} from "../src/contracts/staking/Staking.sol";
import {RewardEscrow} from "../src/contracts/SMX/RewardEscrow.sol";
import {vSMXRedeemer} from "../src/contracts/SMX/vSMXRedeemer.sol";
import {SupplySchedule} from "../src/contracts/SMX/SupplySchedule.sol";
import {MultipleMerkleDistributor} from "../src/contracts/SMX/MultipleMerkleDistributor.sol";

contract SMXTest is Test {
    address public owner = vm.addr(1);
    address public user1 = vm.addr(2);
    address public user2 = vm.addr(3);
    address public user3 = vm.addr(4);
    address public treasury = vm.addr(5);

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Factory factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    SMX public smx;
    Staking public staking;
    RewardEscrow public rewardEscrow;
    vSMXRedeemer public vSmxRedeemer;
    SupplySchedule public supplySchedule;
    MultipleMerkleDistributor public multipleMerkleDistributor;

    function setUp() public {
        deal(owner, 500 ether);
        deal(user1, 500 ether);
        deal(user2, 500 ether);
        deal(user3, 500 ether);

        deal(WETH, owner, 500 ether);
        deal(WETH, user1, 500 ether);
        deal(WETH, user2, 500 ether);
        deal(WETH, user3, 500 ether);

        vm.startPrank(owner);

        smx = new SMX("SMX", "SMX", owner, 100_000_000 ether);
        staking = new Staking(address(smx), address(smx));
        supplySchedule = new SupplySchedule(owner, treasury);
        // vSmxRedeemer = new vSMXRedeemer(address(smx), address(smx));
        rewardEscrow = new RewardEscrow(owner, address(smx));
        multipleMerkleDistributor = new MultipleMerkleDistributor(
            owner,
            address(smx),
            address(rewardEscrow)
        );

        deal(address(smx), owner, 500 ether);
        deal(address(smx), user1, 500 ether);

        factory.createPair(address(smx), WETH);
        address pair = factory.getPair(address(smx), WETH);

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

        supplySchedule.setSMX(address(smx));
        supplySchedule.setStakingRewards(address(staking));
        supplySchedule.setTradingRewards(address(multipleMerkleDistributor));

        // multipleMerkleDistributor.setMerkleRootForEpoch();

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
