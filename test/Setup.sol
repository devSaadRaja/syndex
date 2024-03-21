// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Utils} from "./Utils.sol";

// import "@uniswap/core/contracts/UniswapV2Pair.sol";
// import "@uniswap/core/contracts/UniswapV2Factory.sol";
// import "@uniswap/periphery/contracts/UniswapV2Router02.sol";

import "@uniswap/core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IFeePool} from "../src/interfaces/IFeePool.sol";
import {ISynthetix} from "../src/interfaces/ISynthetix.sol";

import {Proxy} from "../src/contracts/Proxy.sol";
import {Issuer} from "../src/contracts/Issuer.sol";
import {FeePool} from "../src/contracts/FeePool.sol";
import {Synthetix} from "../src/contracts/Synthetix.sol";
import {Proxyable} from "../src/contracts/Proxyable.sol";
import {DebtCache} from "../src/contracts/DebtCache.sol";
import {Exchanger} from "../src/contracts/Exchanger.sol";
// import {SynthSwap} from "../src/contracts/Synthswap.sol";
import {Liquidator} from "../src/contracts/Liquidator.sol";
import {TokenState} from "../src/contracts/TokenState.sol";
import {ProxyERC20} from "../src/contracts/ProxyERC20.sol";
import {EtherWrapper} from "../src/contracts/EtherWrapper.sol";
import {RewardEscrow} from "../src/contracts/RewardEscrow.sol";
import {SystemStatus} from "../src/contracts/SystemStatus.sol";
import {CollateralEth} from "../src/contracts/CollateralEth.sol";
import {ExchangeRates} from "../src/contracts/ExchangeRates.sol";
import {ExchangeState} from "../src/contracts/ExchangeState.sol";
import {MixinResolver} from "../src/contracts/MixinResolver.sol";
import {SynthRedeemer} from "../src/contracts/SynthRedeemer.sol";
import {AggregatorETH} from "../src/contracts/AggregatorETH.sol";
import {WrapperFactory} from "../src/contracts/WrapperFactory.sol";
import {SupplySchedule} from "../src/contracts/SupplySchedule.sol";
import {RewardEscrowV2} from "../src/contracts/RewardEscrowV2.sol";
import {TradingRewards} from "../src/contracts/TradingRewards.sol";
import {CollateralUtil} from "../src/contracts/CollateralUtil.sol";
import {EternalStorage} from "../src/contracts/EternalStorage.sol";
import {SystemSettings} from "../src/contracts/SystemSettings.sol";
import {CircuitBreaker} from "../src/contracts/CircuitBreaker.sol";
import {AddressResolver} from "../src/contracts/AddressResolver.sol";
import {FlexibleStorage} from "../src/contracts/FlexibleStorage.sol";
import {LegacyTokenState} from "../src/contracts/LegacyTokenState.sol";
import {DelegateApprovals} from "../src/contracts/DelegateApprovals.sol";
import {CollateralManager} from "../src/contracts/CollateralManager.sol";
import {LiquidatorRewards} from "../src/contracts/LiquidatorRewards.sol";
import {SynthetixDebtShare} from "../src/contracts/SynthetixDebtShare.sol";
import {RewardsDistribution} from "../src/contracts/RewardsDistribution.sol";
import {AggregatorDebtRatio} from "../src/contracts/AggregatorDebtRatio.sol";
import {MultiCollateralSynth} from "../src/contracts/MultiCollateralSynth.sol";
import {AggregatorCollateral} from "../src/contracts/AggregatorCollateral.sol";
import {FuturesMarketManager} from "../src/contracts/FuturesMarketManager.sol";
import {RewardEscrowV2Frozen} from "../src/contracts/RewardEscrowV2Frozen.sol";
import {RewardEscrowV2Storage} from "../src/contracts/RewardEscrowV2Storage.sol";
import {FeePoolEternalStorage} from "../src/contracts/FeePoolEternalStorage.sol";
import {CollateralManagerState} from "../src/contracts/CollateralManagerState.sol";
import {AggregatorIssuedSynths} from "../src/contracts/AggregatorIssuedSynths.sol";
import {DirectIntegrationManager} from "../src/contracts/DirectIntegrationManager.sol";

contract Setup is Test, Utils {
    address public owner = 0xE536B4D7cf1e346D985cEe807e16B1b11B019976;
    address public user1 = 0x599A67bE30BF26e71c641de4fDc05Ac4c519949B;
    address public user2 = 0x338E0c5371f1aA615d33254055d23698e635541e;
    address public user3 = 0xc7610Cd97B0539FAA2E78d9c66C64c60ba3998Bf;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Factory factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // UniswapV2Factory factory = new UniswapV2Factory(owner);
    // UniswapV2Router02 router = new UniswapV2Router02(address(factory), owner);

    bytes32[] public names;
    address[] public addresses;

    Issuer public issuer;
    ProxyERC20 public proxySNX;
    ProxyERC20 public proxysUSD;
    ProxyERC20 public proxysETH;
    FeePool public feePool;
    DebtCache public debtCache;
    // SynthSwap public synthSwap;
    Synthetix public synthetix;
    Exchanger public exchanger;
    Liquidator public liquidator;
    EtherWrapper public etherWrapper;
    RewardEscrow public rewardEscrow;
    TokenState public tokenStatesUSD;
    TokenState public tokenStatesETH;
    SystemStatus public systemStatus;
    CollateralEth public collateralETH;
    ExchangeState public exchangeState;
    SynthRedeemer public synthRedeemer;
    MixinResolver public mixinResolver;
    SupplySchedule public supplySchedule;
    TradingRewards public tradingRewards;
    RewardEscrowV2 public rewardEscrowV2;
    CollateralUtil public collateralUtil;
    EternalStorage public eternalStorage;
    SystemSettings public systemSettings;
    CircuitBreaker public circuitBreaker;
    WrapperFactory public wrapperFactory;
    LegacyTokenState public tokenStateSNX;
    MultiCollateralSynth public synthsUSD;
    MultiCollateralSynth public synthsETH;
    FlexibleStorage public flexibleStorage;
    AddressResolver public addressResolver;
    DelegateApprovals public delegateApprovals;
    CollateralManager public collateralManager;
    LiquidatorRewards public liquidatorRewards;
    SynthetixDebtShare public synthetixDebtShare;
    RewardsDistribution public rewardsDistribution;
    RewardEscrowV2Frozen public rewardEscrowV2Frozen;
    FuturesMarketManager public futuresMarketManager;
    RewardEscrowV2Storage public rewardEscrowV2Storage;
    FeePoolEternalStorage public feePoolEternalStorage;
    CollateralManagerState public collateralManagerState;
    DirectIntegrationManager public directIntegrationManager;

    ExchangeRates public exchangeRates;

    // address public exchangeRatesMainnet;

    // address public aggregatorDebtRatioMainnet;
    AggregatorDebtRatio public aggregatorDebtRatio;
    // address public aggregatorIssuedSynthsMainnet;
    AggregatorIssuedSynths public aggregatorIssuedSynths;

    AggregatorETH public aggregatorETH;
    AggregatorCollateral public aggregatorCollateral;

    function setUp() public virtual {
        deal(owner, 500 ether);
        deal(user1, 500 ether);
        deal(user2, 500 ether);
        deal(user3, 500 ether);

        deal(WETH, owner, 500 ether);
        deal(WETH, user1, 500 ether);
        deal(WETH, user2, 500 ether);
        deal(WETH, user3, 500 ether);

        vm.startPrank(owner); // OWNER

        // // ------------------------------
        // DEPLOYMENTS ---
        // // ------------------------------

        addressResolver = new AddressResolver(owner);
        mixinResolver = new MixinResolver(address(addressResolver));

        collateralUtil = new CollateralUtil(address(addressResolver));
        collateralManagerState = new CollateralManagerState(owner, owner);
        collateralManager = new CollateralManager(
            address(collateralManagerState),
            owner,
            address(addressResolver),
            75000000 * 10 ** 18,
            0.2 * 10 ** 18,
            0,
            0
        );
        collateralETH = new CollateralEth(
            owner,
            address(collateralManager),
            address(addressResolver),
            "sETH",
            1.5 * 10 ** 18, // 100 / 150, 150%
            0.1 * 10 ** 18
        );

        proxySNX = new ProxyERC20(owner);
        proxysUSD = new ProxyERC20(owner);
        proxysETH = new ProxyERC20(owner);
        systemStatus = new SystemStatus(owner);
        issuer = new Issuer(owner, address(addressResolver));
        debtCache = new DebtCache(owner, address(addressResolver));
        exchanger = new Exchanger(owner, address(addressResolver));
        synthRedeemer = new SynthRedeemer(address(addressResolver));
        liquidator = new Liquidator(owner, address(addressResolver));
        exchangeState = new ExchangeState(owner, address(exchanger));
        flexibleStorage = new FlexibleStorage(address(addressResolver));
        systemSettings = new SystemSettings(owner, address(addressResolver));
        circuitBreaker = new CircuitBreaker(owner, address(addressResolver));
        tokenStateSNX = new LegacyTokenState(owner, address(synthetix));
        tokenStatesUSD = new TokenState(owner, address(synthsUSD));
        tokenStatesETH = new TokenState(owner, address(synthsETH));
        wrapperFactory = new WrapperFactory(owner, address(addressResolver));
        rewardEscrowV2 = new RewardEscrowV2(owner, address(addressResolver));
        supplySchedule = new SupplySchedule(owner, 1551830400, 4);
        tradingRewards = new TradingRewards(
            owner,
            owner,
            address(addressResolver)
        );
        directIntegrationManager = new DirectIntegrationManager(
            owner,
            address(addressResolver)
        );
        feePoolEternalStorage = new FeePoolEternalStorage(
            owner,
            address(feePool)
        );
        rewardEscrow = new RewardEscrow(
            owner,
            ISynthetix(address(synthetix)),
            IFeePool(address(feePool))
        );
        etherWrapper = new EtherWrapper(
            owner,
            address(addressResolver),
            payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
        );
        futuresMarketManager = new FuturesMarketManager(
            owner,
            address(addressResolver)
        );
        liquidatorRewards = new LiquidatorRewards(
            owner,
            address(addressResolver)
        );
        synthetixDebtShare = new SynthetixDebtShare(
            owner,
            address(addressResolver)
        );
        synthetix = new Synthetix(
            payable(address(proxySNX)),
            TokenState(address(tokenStateSNX)),
            owner,
            0,
            address(addressResolver)
        );
        synthsUSD = new MultiCollateralSynth(
            payable(address(proxysUSD)),
            tokenStatesUSD,
            "SynthsUSD",
            "sUSD",
            owner,
            "sUSD",
            0,
            address(addressResolver)
        );
        synthsETH = new MultiCollateralSynth(
            payable(address(proxysETH)),
            tokenStatesETH,
            "SynthsETH",
            "sETH",
            owner,
            "sETH",
            0,
            address(addressResolver)
        );
        // synthSwap = new SynthSwap(
        //     address(synthsUSD),
        //     address(router),
        //     address(addressResolver),
        //     owner,
        //     owner
        // );
        rewardEscrowV2Storage = new RewardEscrowV2Storage(
            owner,
            address(rewardEscrowV2)
        );
        feePool = new FeePool(
            payable(address(proxysUSD)),
            owner,
            address(addressResolver)
        );
        rewardsDistribution = new RewardsDistribution(
            owner,
            address(synthetix),
            address(proxySNX),
            address(rewardEscrowV2),
            address(feePool) // feePoolProxy
        );
        rewardEscrowV2Frozen = new RewardEscrowV2Frozen(
            owner,
            address(addressResolver)
        );
        eternalStorage = new EternalStorage(owner, address(synthsUSD));
        delegateApprovals = new DelegateApprovals(owner, eternalStorage);

        exchangeRates = new ExchangeRates(owner, address(addressResolver));
        // exchangeRatesMainnet = 0x648280dD2db772CD018A0CEC72fab5bF8B7683AB;

        aggregatorETH = new AggregatorETH(addressResolver);
        aggregatorCollateral = new AggregatorCollateral(addressResolver);

        aggregatorIssuedSynths = new AggregatorIssuedSynths(addressResolver);
        // aggregatorIssuedSynthsMainnet = 0xcf1405b18dBCEA2893Abe635c88359C75878B9e1;

        aggregatorDebtRatio = new AggregatorDebtRatio(addressResolver);
        // aggregatorDebtRatioMainnet = 0x977d0DD7eA212E9ca1dcD4Ec15cd7Ceb135fa68D;

        // // ------------------------------
        // RESOLVER ADDRESSES ---
        // // ------------------------------

        names.push("AddressResolver");
        addresses.push(address(addressResolver));
        names.push("MixinResolver");
        addresses.push(address(mixinResolver));
        names.push("Proxy");
        addresses.push(address(proxysUSD));
        names.push("SystemStatus");
        addresses.push(address(systemStatus));
        names.push("TokenStateSynthetix");
        addresses.push(address(tokenStateSNX));
        names.push("TokenStatesUSD");
        addresses.push(address(tokenStatesUSD));
        names.push("ext:AggregatorIssuedSynths");
        addresses.push(address(aggregatorIssuedSynths));
        names.push("ext:AggregatorDebtRatio");
        addresses.push(address(aggregatorDebtRatio));
        names.push("FlexibleStorage");
        addresses.push(address(flexibleStorage));
        names.push("ExchangeState");
        addresses.push(address(exchangeState));
        names.push("DelegateApprovals");
        addresses.push(address(delegateApprovals));
        names.push("RewardsDistribution");
        addresses.push(address(rewardsDistribution));
        names.push("RewardEscrowV2Storage");
        addresses.push(address(rewardEscrowV2Storage));
        names.push("RewardEscrow");
        addresses.push(address(rewardEscrow));
        names.push("SupplySchedule");
        addresses.push(address(supplySchedule));
        names.push("FeePoolEternalStorage");
        addresses.push(address(feePoolEternalStorage));
        // ---------------------------------------------
        names.push("DirectIntegrationManager");
        addresses.push(address(directIntegrationManager));
        names.push("RewardEscrowV2");
        addresses.push(address(rewardEscrowV2));
        names.push("ExchangeRates");
        addresses.push(address(exchangeRates));
        names.push("Issuer");
        addresses.push(address(issuer));
        names.push("LiquidatorRewards");
        addresses.push(address(liquidatorRewards));
        names.push("SynthetixDebtShare");
        addresses.push(address(synthetixDebtShare));
        names.push("Synthetix");
        addresses.push(address(synthetix));
        names.push("SynthsUSD");
        addresses.push(address(synthsUSD));
        names.push("SynthsETH");
        addresses.push(address(synthsETH));
        names.push("FeePool");
        addresses.push(address(feePool));
        names.push("DebtCache");
        addresses.push(address(debtCache));
        names.push("CircuitBreaker");
        addresses.push(address(circuitBreaker));
        names.push("SystemSettings");
        addresses.push(address(systemSettings));
        names.push("Exchanger");
        addresses.push(address(exchanger));
        names.push("Liquidator");
        addresses.push(address(liquidator));
        names.push("SynthRedeemer");
        addresses.push(address(synthRedeemer));
        names.push("CollateralManager");
        addresses.push(address(collateralManager));
        names.push("CollateralETH");
        addresses.push(address(collateralETH));
        names.push("CollateralUtil");
        addresses.push(address(collateralUtil));
        names.push("FuturesMarketManager");
        addresses.push(address(futuresMarketManager));
        names.push("EtherWrapper");
        addresses.push(address(etherWrapper));
        names.push("WrapperFactory");
        addresses.push(address(wrapperFactory));
        names.push("TradingRewards");
        addresses.push(address(tradingRewards));

        addressResolver.importAddresses(names, addresses);
        for (uint i = 16; i < addresses.length; i++) {
            MixinResolver(addresses[i]).rebuildCache();
        }

        // for (uint i = 0; i < addresses.length; i++) {
        //     // console.logBytes32(names[i]);
        //     // console.log(addresses[i]);
        //     console.log(string(abi.encodePacked(names[i])), addresses[i]);
        // }

        // // ---------------------------------------------------------------------
        // // ---------------------------------------------------------------------
        // // ---------------------------------------------------------------------

        bytes32[] memory _synthNamesInResolver = new bytes32[](2);
        bytes32[] memory _synthKeys = new bytes32[](2);
        _synthNamesInResolver[0] = "SynthsUSD";
        _synthKeys[0] = "sUSD";
        _synthNamesInResolver[1] = "SynthsETH";
        _synthKeys[1] = "sETH";
        collateralETH.addSynths(_synthNamesInResolver, _synthKeys);
        collateralManager.addSynths(_synthNamesInResolver, _synthKeys);

        address[] memory collateralAddresses = new address[](1);
        collateralAddresses[0] = address(collateralETH);
        collateralManager.addCollaterals(collateralAddresses);

        issuer.addSynth(address(synthsUSD));
        issuer.addSynth(address(synthsETH));

        proxySNX.setTarget(Proxyable(address(synthetix)));
        proxysUSD.setTarget(Proxyable(address(synthsUSD)));
        proxysETH.setTarget(Proxyable(address(synthsETH)));

        tokenStateSNX.setAssociatedContract(address(synthetix));
        tokenStatesUSD.setAssociatedContract(address(synthsUSD));
        tokenStatesETH.setAssociatedContract(address(synthsETH));
        collateralManagerState.setAssociatedContract(
            address(collateralManager)
        );
        rewardEscrowV2Storage.setFallbackRewardEscrow(
            address(rewardEscrowV2Frozen)
        );
        exchangeRates.addAggregator("SNX", address(aggregatorCollateral));
        exchangeRates.addAggregator("sETH", address(aggregatorETH));
        // exchangeRates.addAggregator(
        //     "ext:AggregatorDebtRatio",
        //     address(aggregatorDebtRatio)
        // );
        // exchangeRates.addAggregator(
        //     "ext:AggregatorIssuedSynths",
        //     address(aggregatorIssuedSynths)
        // );

        // console.log(
        //     "address(aggregatorCollateral)",
        //     address(aggregatorCollateral)
        // );
        // console.log(
        //     "address(aggregatorDebtRatio)",
        //     address(aggregatorDebtRatio)
        // );

        // 200000000000000000, 0.2   = 100 / 500%
        // 625000000000000000, 0.625 = 100 / 160%
        // 100000000000000000, 0.1   = 10% / 100
        // 600000000000000000, 0.6   = 60% / 100
        // 500000000000000000, 0.5   = 50% / 100

        systemSettings.setIssuanceRatio(0.2 * 10 ** 18);
        // systemSettings.setIssuanceRatio(0.8 * 10 ** 18); // 125%
        systemSettings.setLiquidationRatio(0.625 * 10 ** 18);
        // systemSettings.setLiquidationPenalty(100000000000000000);
        systemSettings.setSnxLiquidationPenalty(0.6 * 10 ** 18); // forced
        systemSettings.setSelfLiquidationPenalty(0.5 * 10 ** 18);
        systemSettings.setLiquidationDelay(28800);
        systemSettings.setRateStalePeriod(86400);
        systemSettings.setPriceDeviationThresholdFactor(100 * 10 ** 18);

        // // uint256 val = 100;
        // // uint256 minCratio = 150;
        // systemSettings.setIssuanceRatio(0.66 * 10 ** 18); // 150%
        // systemSettings.setLiquidationRatio(0.8 * 10 ** 18);
        // systemSettings.setSnxLiquidationPenalty(0.5 * 10 ** 18); // 50%
        // systemSettings.setLiquidationDelay(28800); // 8 hours
        // systemSettings.setRateStalePeriod(86400); // 1 day

        supplySchedule.setSynthetixProxy(ISynthetix(address(proxySNX)));
        supplySchedule.setInflationAmount(3000000 * 10 ** 18);

        vm.stopPrank(); // OWNER
    }
}
