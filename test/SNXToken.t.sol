// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Utils} from "./Utils.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {IMixinResolver} from "../src/interfaces/IMixinResolver.sol";

import {Issuer} from "../src/contracts/Issuer.sol";
import {SynDex} from "../src/contracts/SynDex.sol";
import {ProxyERC20} from "../src/contracts/ProxyERC20.sol";
import {SystemStatus} from "../src/contracts/SystemStatus.sol";
import {AddressResolver} from "../src/contracts/AddressResolver.sol";
import {LegacyTokenState} from "../src/contracts/LegacyTokenState.sol";
import {SynDexDebtShare} from "../src/contracts/SynDexDebtShare.sol";

contract SFCXToken is Test, Utils {
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
    SynDex public syndex;
    ProxyERC20 public proxySFCX;
    SystemStatus public systemStatus;
    LegacyTokenState public tokenStateSFCX;
    AddressResolver public addressResolver;
    SynDexDebtShare public syndexDebtShare;

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

        proxySFCX = new ProxyERC20(owner);
        systemStatus = new SystemStatus(owner);
        issuer = new Issuer(owner, address(addressResolver));
        tokenStateSFCX = new LegacyTokenState(owner, address(syndex));
        syndexDebtShare = new SynDexDebtShare(owner, address(addressResolver));
        syndex = new SynDex(
            payable(address(proxySFCX)),
            address(tokenStateSFCX),
            owner,
            0,
            address(addressResolver)
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
        names.push("SynDexDebtShare");
        addresses.push(address(syndexDebtShare));
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
        names.push("SynDex");
        addresses.push(address(syndex));
        names.push("Issuer");
        addresses.push(address(issuer));

        addressResolver.loadAddresses(names, addresses);
        for (uint i = count; i < addresses.length; i++) {
            IMixinResolver(addresses[i]).refreshCache();
        }

        // // ---------------------------------------------------------------------
        // // ---------------------------------------------------------------------
        // // ---------------------------------------------------------------------

        proxySFCX.updateTarget(address(syndex));

        tokenStateSFCX.linkContract(address(syndex));

        factory.createPair(address(proxySFCX), WETH);
        address pairSFCXWETH = factory.getPair(address(proxySFCX), WETH);

        syndex.mint(owner, 1_000_000 ether);
        syndex.setReserveAddress(reserveAddr);
        syndex.setPool(pairSFCXWETH, true);
        syndex.setTrade(true);

        proxySFCX.transfer(user1, 1000 ether);
        proxySFCX.transfer(user2, 1000 ether);
        proxySFCX.transfer(user3, 1000 ether);
        proxySFCX.transfer(reserveAddr, 200000 ether);

        proxySFCX.approve(user4, 1000 ether);

        vm.stopPrank(); // OWNER

        vm.startPrank(user4);
        proxySFCX.transferFrom(owner, user4, 10 ether);
        vm.stopPrank();
    }

    function testTrade() public {
        assertEq(proxySFCX.totalSupply(), 1000000 ether);
        
        assertEq(proxySFCX.balanceOf(owner), 796990 ether);
        assertEq(proxySFCX.balanceOf(user4), 10 ether);

        vm.startPrank(owner);
        proxySFCX.approve(address(router), 50 ether);
        IERC20(WETH).approve(address(router), 50 ether);
        router.addLiquidity(
            address(proxySFCX),
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

        assertEq(proxySFCX.balanceOf(user1), 1000 ether);
        assertEq(IERC20(WETH).balanceOf(user1), 100 ether);

        _swap(WETH, address(proxySFCX), 10 ether, user1); // * BUY
        _swap(address(proxySFCX), WETH, 8 ether, user1); // * SELL

        assertGt(proxySFCX.balanceOf(user1), 1000 ether);
        assertLt(IERC20(WETH).balanceOf(user1), 100 ether);

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
