// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Utils} from "./Utils.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {IMixinResolver} from "../src/interfaces/IMixinResolver.sol";

import {Issuer} from "../src/contracts/Issuer.sol";
import {Taxable} from "../src/contracts/tax/Taxable.sol";
import {Synthetix} from "../src/contracts/Synthetix.sol";
import {ProxyERC20} from "../src/contracts/ProxyERC20.sol";
import {SystemStatus} from "../src/contracts/SystemStatus.sol";
import {AddressResolver} from "../src/contracts/AddressResolver.sol";
import {LegacyTokenState} from "../src/contracts/LegacyTokenState.sol";
import {SynthetixDebtShare} from "../src/contracts/SynthetixDebtShare.sol";

contract SCFXToken is Test, Utils {
    address public owner = vm.addr(1);
    address public user1 = vm.addr(2);
    address public user2 = vm.addr(3);
    address public user3 = vm.addr(4);
    address public user4 = vm.addr(5);
    address public reserveAddr = vm.addr(7);

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Factory factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bytes32[] public names;
    address[] public addresses;

    Issuer public issuer;
    Taxable public taxable;
    Synthetix public synthetix;
    ProxyERC20 public proxySCFX;
    SystemStatus public systemStatus;
    LegacyTokenState public tokenStateSCFX;
    AddressResolver public addressResolver;
    SynthetixDebtShare public synthetixDebtShare;

    function setUp() public {
        deal(owner, 100 ether);
        deal(user1, 100 ether);
        deal(user2, 100 ether);
        deal(user3, 100 ether);

        deal(WETH, owner, 100 ether);
        deal(WETH, user1, 100 ether);
        deal(WETH, user2, 100 ether);
        deal(WETH, user3, 100 ether);

        vm.startPrank(owner); // OWNER

        // // ------------------------------
        // DEPLOYMENTS ---
        // // ------------------------------

        addressResolver = new AddressResolver(owner);

        proxySCFX = new ProxyERC20(owner);
        systemStatus = new SystemStatus(owner);
        issuer = new Issuer(owner, address(addressResolver));
        tokenStateSCFX = new LegacyTokenState(owner, address(synthetix));
        synthetixDebtShare = new SynthetixDebtShare(
            owner,
            address(addressResolver)
        );
        synthetix = new Synthetix(
            payable(address(proxySCFX)),
            address(tokenStateSCFX),
            owner,
            0,
            address(addressResolver)
        );

        taxable = new Taxable(
            address(proxySCFX),
            address(synthetix),
            WETH,
            address(router)
        );

        // // ------------------------------
        // RESOLVER ADDRESSES ---
        // // ------------------------------

        uint8 count = 0;

        names.push("SystemStatus");
        addresses.push(address(systemStatus));
        count++;
        names.push("RewardsDistribution");
        addresses.push(owner);
        count++;
        names.push("RewardEscrow");
        addresses.push(owner);
        count++;
        names.push("FlexibleStorage");
        addresses.push(owner);
        count++;
        names.push("DelegateApprovals");
        addresses.push(owner);
        count++;
        names.push("ext:AggregatorIssuedSynths");
        addresses.push(owner);
        count++;
        names.push("ext:AggregatorDebtRatio");
        addresses.push(owner);
        count++;
        // ! --- refreshCache vvv
        names.push("SynthetixDebtShare");
        addresses.push(address(synthetixDebtShare));
        count++;
        names.push("Exchanger");
        addresses.push(owner);
        count++;
        names.push("LiquidatorRewards");
        addresses.push(owner);
        count++;
        names.push("Liquidator");
        addresses.push(owner);
        count++;
        names.push("RewardEscrowV2");
        addresses.push(owner);
        count++;
        names.push("ExchangeRates");
        addresses.push(owner);
        count++;
        names.push("CircuitBreaker");
        addresses.push(owner);
        count++;
        names.push("FeePool");
        addresses.push(owner);
        count++;
        names.push("DebtCache");
        addresses.push(owner);
        count++;
        names.push("SynthRedeemer");
        addresses.push(owner);
        count++;
        // ? ---
        names.push("Synthetix");
        addresses.push(address(synthetix));
        names.push("Issuer");
        addresses.push(address(issuer));

        addressResolver.loadAddresses(names, addresses);
        for (uint i = count; i < addresses.length; i++) {
            IMixinResolver(addresses[i]).refreshCache();
        }

        // // ---------------------------------------------------------------------
        // // ---------------------------------------------------------------------
        // // ---------------------------------------------------------------------

        proxySCFX.updateTarget(address(synthetix));

        tokenStateSCFX.linkContract(address(synthetix));

        factory.createPair(address(proxySCFX), WETH);
        address pairSCFXWETH = factory.getPair(address(proxySCFX), WETH);

        taxable.setExcludeFromFee(address(taxable), true);
        taxable.setRewardAddress(address(WETH));
        taxable.setRouter(address(router));
        taxable.setFeeTaker(user2, 100);
        taxable.setPool(pairSCFXWETH, true);

        synthetix.mint(owner, 1_000_000 ether);
        synthetix.setReserveAddress(reserveAddr);
        synthetix.setTaxable(address(taxable));
        synthetix.setDeploy(true);
        synthetix.setTrade(true);

        proxySCFX.transfer(user1, 1000 ether);
        proxySCFX.transfer(user2, 1000 ether);
        proxySCFX.transfer(user3, 1000 ether);
        proxySCFX.transfer(reserveAddr, 200000 ether);

        proxySCFX.approve(user4, 1000 ether);

        vm.stopPrank(); // OWNER

        vm.startPrank(user4);
        proxySCFX.transferFrom(owner, user4, 10 ether);
        vm.stopPrank();

        console.log(proxySCFX.balanceOf(owner), "<<< balanceOf(owner)");
        console.log(proxySCFX.balanceOf(user4), "<<< balanceOf(user4)");

        console.log(proxySCFX.totalSupply(), "<<< totalSupply");
    }

    function testTaxSCFX() public {
        vm.startPrank(owner);
        proxySCFX.approve(address(router), 50 ether);
        IERC20(WETH).approve(address(router), 50 ether);
        router.addLiquidity(
            address(proxySCFX),
            WETH,
            50 ether,
            50 ether,
            0,
            0,
            owner,
            block.timestamp + 10 minutes
        );
        vm.stopPrank();

        vm.startPrank(user1);

        console.log();
        console.log(taxable.threshold(), "<-- threshold");
        console.log(taxable.currentFeeAmount(), "<-- currentFeeAmount");
        console.log(
            proxySCFX.balanceOf(address(taxable)),
            "<-- SCFX balanceOf taxable"
        );
        console.log(IERC20(WETH).balanceOf(user1), "<-- WETH balanceOf user1");
        console.log(IERC20(WETH).balanceOf(user2), "<-- WETH balanceOf user2");

        _swap(WETH, address(proxySCFX), 10 ether, user1); // * BUY
        _swap(address(proxySCFX), WETH, 8 ether, user1); // * SELL

        console.log();
        console.log("BEFORE TRANSFER");
        console.log(taxable.threshold(), "<-- threshold");
        console.log(taxable.currentFeeAmount(), "<-- currentFeeAmount");
        console.log(
            proxySCFX.balanceOf(address(taxable)),
            "<-- SCFX balanceOf taxable"
        );
        console.log(IERC20(WETH).balanceOf(user1), "<-- WETH balanceOf user1");
        console.log(IERC20(WETH).balanceOf(user2), "<-- WETH balanceOf user2");

        proxySCFX.transfer(user3, 1 ether);

        vm.stopPrank();

        console.log();
        console.log("AFTER");
        console.log(taxable.threshold(), "<-- threshold");
        console.log(taxable.currentFeeAmount(), "<-- currentFeeAmount");
        console.log(
            proxySCFX.balanceOf(address(taxable)),
            "<-- SCFX balanceOf taxable"
        );
        console.log(IERC20(WETH).balanceOf(user1), "<-- WETH balanceOf user1");
        console.log(IERC20(WETH).balanceOf(user2), "<-- WETH balanceOf user2");
        console.log(IERC20(WETH).balanceOf(user3), "<-- WETH balanceOf user3");
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
