// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol";

import {Depot} from "../src/contracts/Depot.sol";
import {Proxy} from "../src/contracts/Proxy.sol";
import {Issuer} from "../src/contracts/Issuer.sol";
import {FeePool} from "../src/contracts/FeePool.sol";
import {Token} from "../src/contracts/test/Token.sol";
import {SynDex} from "../src/contracts/SynDex.sol";
import {DebtCache} from "../src/contracts/DebtCache.sol";
import {Exchanger} from "../src/contracts/Exchanger.sol";
import {SynthUtil} from "../src/contracts/SynthUtil.sol";
import {SynthSwap} from "../src/contracts/Synthswap.sol";
import {ProxyERC20} from "../src/contracts/ProxyERC20.sol";
import {Liquidator} from "../src/contracts/Liquidator.sol";
import {TokenState} from "../src/contracts/TokenState.sol";
import {FeePoolState} from "../src/contracts/FeePoolState.sol";
import {EtherWrapper} from "../src/contracts/EtherWrapper.sol";
import {RewardEscrow} from "../src/contracts/RewardEscrow.sol";
import {SystemStatus} from "../src/contracts/SystemStatus.sol";
import {CollateralEth} from "../src/contracts/CollateralEth.sol";
import {ExchangeRates} from "../src/contracts/ExchangeRates.sol";
import {ExchangeState} from "../src/contracts/ExchangeState.sol";
import {SynthRedeemer} from "../src/contracts/SynthRedeemer.sol";
import {SynDexState} from "../src/contracts/SynDexState.sol";
import {WrapperFactory} from "../src/contracts/WrapperFactory.sol";
import {RewardEscrowV2} from "../src/contracts/RewardEscrowV2.sol";
import {TradingRewards} from "../src/contracts/TradingRewards.sol";
import {CollateralUtil} from "../src/contracts/CollateralUtil.sol";
import {EternalStorage} from "../src/contracts/EternalStorage.sol";
import {SystemSettings} from "../src/contracts/SystemSettings.sol";
import {CircuitBreaker} from "../src/contracts/CircuitBreaker.sol";
import {AggregatorSynth} from "../src/contracts/AggregatorSynth.sol";
import {CollateralErc20} from "../src/contracts/CollateralErc20.sol";
import {AddressResolver} from "../src/contracts/AddressResolver.sol";
import {FlexibleStorage} from "../src/contracts/FlexibleStorage.sol";
import {LegacyTokenState} from "../src/contracts/LegacyTokenState.sol";
import {DelegateApprovals} from "../src/contracts/DelegateApprovals.sol";
import {CollateralManager} from "../src/contracts/CollateralManager.sol";
import {LiquidatorRewards} from "../src/contracts/LiquidatorRewards.sol";
import {SynDexDebtShare} from "../src/contracts/SynDexDebtShare.sol";
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

contract Deploy is Script {
    uint256 public privateKeyDeployer = vm.envUint("PRIVATE_KEY");

    address public deployer = vm.addr(privateKeyDeployer);
    address public treasury = deployer;

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // ETH mainnet
    ISwapRouter public swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // ETH mainnet

    bytes32[] public names;
    address[] public addresses;

    Depot public depot;
    Token public token;
    Issuer public issuer;
    SynDex public syndex;
    FeePool public feePool;
    Proxy public proxyFeePool;
    DebtCache public debtCache;
    Exchanger public exchanger;
    SynthSwap public synthSwap;
    ProxyERC20 public proxySFCX;
    SynthUtil public synthUtil;
    ProxyERC20 public proxycfUSD;
    ProxyERC20 public proxycfETH;
    Liquidator public liquidator;
    FeePoolState public feePoolState;
    EtherWrapper public etherWrapper;
    RewardEscrow public rewardEscrow;
    TokenState public tokenStatecfUSD;
    TokenState public tokenStatecfETH;
    SystemStatus public systemStatus;
    CollateralEth public collateralETH;
    ExchangeState public exchangeState;
    SynthRedeemer public synthRedeemer;
    ExchangeRates public exchangeRates;
    SynDexState public syndexState;
    TradingRewards public tradingRewards;
    RewardEscrowV2 public rewardEscrowV2;
    CollateralUtil public collateralUtil;
    EternalStorage public eternalStorage;
    SystemSettings public systemSettings;
    CircuitBreaker public circuitBreaker;
    WrapperFactory public wrapperFactory;
    LegacyTokenState public tokenStateSFCX;
    MultiCollateralSynth public synthcfUSD;
    MultiCollateralSynth public synthcfETH;
    FlexibleStorage public flexibleStorage;
    AddressResolver public addressResolver;
    CollateralErc20 public collateralErc20;
    DelegateApprovals public delegateApprovals;
    CollateralManager public collateralManager;
    LiquidatorRewards public liquidatorRewards;
    SynDexDebtShare public syndexDebtShare;
    RewardsDistribution public rewardsDistribution;
    RewardEscrowV2Frozen public rewardEscrowV2Frozen;
    FuturesMarketManager public futuresMarketManager;
    RewardEscrowV2Storage public rewardEscrowV2Storage;
    FeePoolEternalStorage public feePoolEternalStorage;
    CollateralManagerState public collateralManagerState;
    DirectIntegrationManager public directIntegrationManager;

    AggregatorSynth public aggregatorSynth;
    AggregatorDebtRatio public aggregatorDebtRatio;
    AggregatorCollateral public aggregatorCollateral;
    AggregatorIssuedSynths public aggregatorIssuedSynths;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(privateKeyDeployer); // DEPLOYER

        addressResolver = new AddressResolver(deployer);
        // token = new Token("My Token", "TKN", deployer, 100_000_000 ether);
        // synthUtil = new SynthUtil(address(addressResolver));
        // collateralUtil = new CollateralUtil(address(addressResolver));
        // collateralManagerState = new CollateralManagerState(deployer, deployer);
        // collateralManager = new CollateralManager(
        //     address(collateralManagerState),
        //     deployer,
        //     address(addressResolver),
        //     75000000 ether,
        //     0.2 ether,
        //     0,
        //     0
        // );
        // collateralETH = new CollateralEth(
        //     deployer,
        //     address(collateralManager),
        //     address(addressResolver),
        //     "cfETH",
        //     1.5 ether, // 150 / 100, 150%
        //     0.1 ether
        // );
        // collateralErc20 = new CollateralErc20(
        //     deployer,
        //     address(collateralManager),
        //     address(addressResolver),
        //     "SMX",
        //     1.5 ether, // 150 / 100, 150%
        //     0.1 ether,
        //     address(token),
        //     18
        // );
        // proxyFeePool = new Proxy(deployer);
        // proxySFCX = new ProxyERC20(deployer);
        // proxycfUSD = new ProxyERC20(deployer);
        // proxycfETH = new ProxyERC20(deployer);
        // systemStatus = new SystemStatus(deployer);
        // issuer = new Issuer(deployer, address(addressResolver));
        // debtCache = new DebtCache(deployer, address(addressResolver));
        // exchanger = new Exchanger(deployer, address(addressResolver));
        // synthRedeemer = new SynthRedeemer(address(addressResolver));
        // liquidator = new Liquidator(deployer, address(addressResolver));
        // exchangeState = new ExchangeState(deployer, address(exchanger));
        // flexibleStorage = new FlexibleStorage(address(addressResolver));
        // systemSettings = new SystemSettings(deployer, address(addressResolver));
        // circuitBreaker = new CircuitBreaker(deployer, address(addressResolver));
        // syndexState = new SynDexState(deployer, address(syndex));
        // tokenStateSFCX = new LegacyTokenState(deployer, address(syndex));
        // tokenStatecfUSD = new TokenState(deployer, address(synthcfUSD));
        // tokenStatecfETH = new TokenState(deployer, address(synthcfETH));
        // wrapperFactory = new WrapperFactory(deployer, address(addressResolver));
        // depot = new Depot(
        //     deployer,
        //     payable(treasury),
        //     address(addressResolver)
        // );
        // directIntegrationManager = new DirectIntegrationManager(
        //     deployer,
        //     address(addressResolver)
        // );
        // feePool = new FeePool(
        //     payable(address(proxyFeePool)),
        //     deployer,
        //     address(addressResolver)
        // );
        // feePoolEternalStorage = new FeePoolEternalStorage(
        //     deployer,
        //     address(feePool)
        // );
        // rewardEscrow = new RewardEscrow(
        //     deployer,
        //     address(syndex),
        //     address(feePool)
        // );
        // etherWrapper = new EtherWrapper(
        //     deployer,
        //     address(addressResolver),
        //     payable(WETH)
        // );
        // futuresMarketManager = new FuturesMarketManager(
        //     deployer,
        //     address(addressResolver)
        // );
        // liquidatorRewards = new LiquidatorRewards(
        //     deployer,
        //     address(addressResolver)
        // );
        // syndexDebtShare = new SynDexDebtShare(
        //     deployer,
        //     address(addressResolver)
        // );
        // syndex = new SynDex(
        //     payable(address(proxySFCX)),
        //     address(tokenStateSFCX),
        //     deployer,
        //     0,
        //     address(addressResolver)
        // );
        // synthcfUSD = new MultiCollateralSynth(
        //     payable(address(proxycfUSD)),
        //     address(tokenStatecfUSD),
        //     "SynthcfUSD",
        //     "cfUSD",
        //     deployer,
        //     "cfUSD",
        //     0,
        //     address(addressResolver)
        // );
        // synthcfETH = new MultiCollateralSynth(
        //     payable(address(proxycfETH)),
        //     address(tokenStatecfETH),
        //     "SynthcfETH",
        //     "cfETH",
        //     deployer,
        //     "cfETH",
        //     0,
        //     address(addressResolver)
        // );
        // feePoolState = new FeePoolState(deployer, address(feePool));
        // rewardEscrowV2 = new RewardEscrowV2(deployer, address(addressResolver));
        // rewardEscrowV2Storage = new RewardEscrowV2Storage(
        //     deployer,
        //     address(rewardEscrowV2)
        // );
        // rewardsDistribution = new RewardsDistribution(
        //     deployer,
        //     address(syndex),
        //     address(proxySFCX),
        //     address(rewardEscrowV2),
        //     address(proxyFeePool)
        // );
        // rewardEscrowV2Frozen = new RewardEscrowV2Frozen(
        //     deployer,
        //     address(addressResolver)
        // );
        // eternalStorage = new EternalStorage(deployer, address(synthcfUSD));
        // delegateApprovals = new DelegateApprovals(
        //     deployer,
        //     address(eternalStorage)
        // );
        // synthSwap = new SynthSwap(
        //     address(proxycfUSD),
        //     address(swapRouter),
        //     address(addressResolver),
        //     deployer, // volumeRewards
        //     treasury
        // );
        // tradingRewards = new TradingRewards(
        //     deployer,
        //     deployer, // periodController
        //     address(addressResolver)
        // );
        // exchangeRates = new ExchangeRates(deployer, address(addressResolver));
        // aggregatorSynth = new AggregatorSynth(
        //     "",
        //     1 * 10 ** 8,
        //     address(addressResolver)
        // );
        // aggregatorDebtRatio = new AggregatorDebtRatio(addressResolver);
        // aggregatorIssuedSynths = new AggregatorIssuedSynths(addressResolver);
        // aggregatorCollateral = new AggregatorCollateral(
        //     address(addressResolver)
        // );

        vm.stopBroadcast(); // DEPLOYER
    }
}
