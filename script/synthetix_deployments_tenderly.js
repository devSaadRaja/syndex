const { tenderly } = require("hardhat");

const { readFileSync, writeFileSync } = require("fs");

var url, chainId, outputFilePath;
const option = Number(process.env.TENDERLY_MAIN_OPTION);
if (option == 1) {
  url = process.env.TENDERLY_MAINNET_FORK_URL_TEST;
  outputFilePath = "./tenderly_deployments_test.json";
  chainId = 1;
} else if (option == 2) {
  url = process.env.TENDERLY_MAINNET_FORK_URL;
  outputFilePath = "./tenderly_deployments.json";
  chainId = 1;
} else if (option == 3) {
  url = process.env.TENDERLY_ARBITRUM_FORK_URL;
  outputFilePath = "./tenderly_arb_deployments.json";
  chainId = 42161;
}

const WETH = require("../abis/weth.json");
const uniswapPair = require("../abis/uniswap-pair.json");
const uniswapRouter = require("../abis/uniswap-router.json");
const uniswapFactory = require("../abis/uniswap-factory.json");
const uniswapPoolV3 = require("../abis/uniswap-pool-v3.json");
const uniswapFactoryV3 = require("../abis/uniswap-factory-v3.json");
const uniswapSwapRouter = require("../abis/uniswap-swaprouter.json");
const uniswapNonfungiblePositionManager = require("../abis/uniswap-nonfungible-position-manager.json");

const { resolve } = require("path");
const { config } = require("dotenv");

config({ path: resolve(__dirname, "./.env") });

const parseEth = (eth) => ethers.utils.parseEther(String(eth));
const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

const contractsPath = {
  Proxy: "src/contracts/Proxy.sol:Proxy",
  Issuer: "src/contracts/Issuer.sol:Issuer",
  ERC20: "src/contracts/SMX/ERC20.sol:ERC20",
  TestToken: "src/contracts/test/Token.sol:Token",
  SynDex: "src/contracts/SynDex.sol:SynDex",
  Exchanger: "src/contracts/Exchanger.sol:Exchanger",
  ProxyERC20: "src/contracts/ProxyERC20.sol:ProxyERC20",
  TokenState: "src/contracts/TokenState.sol:TokenState",
  RewardEscrow: "src/contracts/RewardEscrow.sol:RewardEscrow",
  ExchangeRates: "src/contracts/ExchangeRates.sol:ExchangeRates",
  CollateralETH: "src/contracts/CollateralEth.sol:CollateralEth",
  SystemSettings: "src/contracts/SystemSettings.sol:SystemSettings",
  SynDexState: "src/contracts/SynDexState.sol:SynDexState",
  AddressResolver: "src/contracts/AddressResolver.sol:AddressResolver",
  CollateralManager: "src/contracts/CollateralManager.sol:CollateralManager",
  MultiCollateralSynth:
    "src/contracts/MultiCollateralSynth.sol:MultiCollateralSynth",
  RewardEscrowV2Storage:
    "src/contracts/RewardEscrowV2Storage.sol:RewardEscrowV2Storage",
  CollateralManagerState:
    "src/contracts/CollateralManagerState.sol:CollateralManagerState",
};

const deployments = JSON.parse(readFileSync(outputFilePath, "utf-8"));

const provider_tenderly = new ethers.providers.JsonRpcProvider(url, chainId);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider_tenderly);

const deployer = "0x0f6A0fBb5a9E10f50f364b2409a5Bbb9aFa52059";
const user1 = "0x3555f3e074467D24820f14db7e064302e386a57D";
const user2 = "0xcE4a1e96EB50E62d4920cb6424358404AA5570Be";
const treasury = "0xa6C40e6Ea900EF92FD8459c86FA290a282b0aCE5";
const reserveAddr = "0xEA1b7aF13E723D4598aA384e0b5b80FCB4147F48";

async function main() {
  // ! ------------------------------------------------------------------------
  // ! DEPLOYMENTS ------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  // const SafeDecimalMath = await contractDeploy("SafeDecimalMath", []);
  // deployments["SafeDecimalMath"] = SafeDecimalMath.address;
  // await verify("SafeDecimalMath", SafeDecimalMath.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SystemSettingsLib = await contractDeploy("SystemSettingsLib", [], {
  //   libraries: {
  //     SafeDecimalMath: deployments["SafeDecimalMath"],
  //   },
  // });
  // deployments["SystemSettingsLib"] = SystemSettingsLib.address;
  // await verify("SystemSettingsLib", SystemSettingsLib.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const ExchangeSettlementLib = await contractDeploy(
  //   "ExchangeSettlementLib",
  //   [],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //     },
  //   }
  // );
  // deployments["ExchangeSettlementLib"] = ExchangeSettlementLib.address;
  // await verify("ExchangeSettlementLib", ExchangeSettlementLib.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // // * ------------------------------

  // const AddressResolver = await contractDeploy("AddressResolver", [deployer]);
  // deployments["AddressResolver"] = AddressResolver.address;
  // await verify("AddressResolver", AddressResolver.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SynthUtil = await contractDeploy("SynthUtil", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynthUtil"] = SynthUtil.address;
  // await verify("SynthUtil", SynthUtil.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const CollateralUtil = await contractDeploy(
  //   "CollateralUtil",
  //   [deployments["AddressResolver"]],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //     },
  //   }
  // );
  // deployments["CollateralUtil"] = CollateralUtil.address;
  // await verify("CollateralUtil", CollateralUtil.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const CollateralManagerState = await contractDeploy(
  //   "CollateralManagerState",
  //   [
  //     deployer,
  //     ADDRESS_ZERO, // collateralManager
  //   ]
  // );
  // deployments["CollateralManagerState"] = CollateralManagerState.address;
  // await verify("CollateralManagerState", CollateralManagerState.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const CollateralManager = await contractDeploy("CollateralManager", [
  //   deployments["CollateralManagerState"],
  //   deployer,
  //   deployments["AddressResolver"],
  //   parseEth(75000000),
  //   parseEth(0.2),
  //   0,
  //   0,
  // ]);
  // deployments["CollateralManager"] = CollateralManager.address;
  // await verify("CollateralManager", CollateralManager.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const CollateralEth = await contractDeploy("CollateralEth", [ // ! deploy it later
  //   deployer,
  //   deployments["CollateralManager"],
  //   deployments["AddressResolver"],
  //   ethers.utils.formatBytes32String("cfETH"),
  //   parseEth(1.5), // 100 / 150, 150%
  //   parseEth(0.1),
  // ]);
  // deployments["CollateralEth"] = CollateralEth.address;
  // await verify("CollateralEth", CollateralEth.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const ProxySFCX = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxySFCX"] = ProxySFCX.address;
  // await verify("ProxyERC20", ProxySFCX.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const ProxycfUSD = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxycfUSD"] = ProxycfUSD.address;
  // await verify("ProxyERC20", ProxycfUSD.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const ProxycfETH = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxycfETH"] = ProxycfETH.address;
  // await verify("ProxyERC20", ProxycfETH.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const ProxyFeePool = await contractDeploy("Proxy", [deployer]);
  // deployments["ProxyFeePool"] = ProxyFeePool.address;
  // await verify("Proxy", ProxyFeePool.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SystemStatus = await contractDeploy("SystemStatus", [deployer]);
  // deployments["SystemStatus"] = SystemStatus.address;
  // await verify("SystemStatus", SystemStatus.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const Issuer = await contractDeploy(
  //   "Issuer",
  //   [deployer, deployments["AddressResolver"]],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //     },
  //   }
  // );
  // deployments["Issuer"] = Issuer.address;
  // await verify("Issuer", Issuer.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const DebtCache = await contractDeploy("DebtCache", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["DebtCache"] = DebtCache.address;
  // await verify("DebtCache", DebtCache.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const Exchanger = await contractDeploy(
  //   "Exchanger",
  //   [deployer, deployments["AddressResolver"]],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //       ExchangeSettlementLib: deployments["ExchangeSettlementLib"],
  //     },
  //   }
  // );
  // deployments["Exchanger"] = Exchanger.address;
  // await verify("Exchanger", Exchanger.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  //   ExchangeSettlementLib: deployments["ExchangeSettlementLib"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const ExchangeState = await contractDeploy("ExchangeState", [
  //   deployer,
  //   deployments["Exchanger"],
  // ]);
  // deployments["ExchangeState"] = ExchangeState.address;
  // await verify("ExchangeState", ExchangeState.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SynthRedeemer = await contractDeploy("SynthRedeemer", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynthRedeemer"] = SynthRedeemer.address;
  // await verify("SynthRedeemer", SynthRedeemer.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const Liquidator = await contractDeploy(
  //   "Liquidator",
  //   [deployer, deployments["AddressResolver"]],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //     },
  //   }
  // );
  // deployments["Liquidator"] = Liquidator.address;
  // await verify("Liquidator", Liquidator.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const FlexibleStorage = await contractDeploy("FlexibleStorage", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["FlexibleStorage"] = FlexibleStorage.address;
  // await verify("FlexibleStorage", FlexibleStorage.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SystemSettings = await contractDeploy(
  //   "SystemSettings",
  //   [deployer, deployments["AddressResolver"]],
  //   {
  //     libraries: {
  //       SystemSettingsLib: deployments["SystemSettingsLib"],
  //     },
  //   }
  // );
  // deployments["SystemSettings"] = SystemSettings.address;
  // await verify("SystemSettings", SystemSettings.address, {
  //   SystemSettingsLib: deployments["SystemSettingsLib"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const CircuitBreaker = await contractDeploy("CircuitBreaker", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["CircuitBreaker"] = CircuitBreaker.address;
  // await verify("CircuitBreaker", CircuitBreaker.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SynDexState = await contractDeploy("SynDexState", [
  //   deployer,
  //   ADDRESS_ZERO, // syndex
  // ]);
  // deployments["SynDexState"] = SynDexState.address;
  // await verify("SynDexState", SynDexState.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const TokenStateSFCX = await contractDeploy("LegacyTokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // syndex
  // ]);
  // deployments["TokenStateSFCX"] = TokenStateSFCX.address;
  // await verify("LegacyTokenState", TokenStateSFCX.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const TokenStatecfUSD = await contractDeploy("TokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // synthcfUSD
  // ]);
  // deployments["TokenStatecfUSD"] = TokenStatecfUSD.address;
  // await verify("TokenState", TokenStatecfUSD.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const TokenStatecfETH = await contractDeploy("TokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // synthcfETH
  // ]);
  // deployments["TokenStatecfETH"] = TokenStatecfETH.address;
  // await verify("TokenState", TokenStatecfETH.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const Depot = await contractDeploy(
  //   "Depot",
  //   [deployer, treasury, deployments["AddressResolver"]],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //     },
  //   }
  // );
  // deployments["Depot"] = Depot.address;
  // await verify("Depot", Depot.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const WrapperFactory = await contractDeploy(
  //   "WrapperFactory",
  //   [deployer, deployments["AddressResolver"]],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //     },
  //   }
  // );
  // deployments["WrapperFactory"] = WrapperFactory.address;
  // await verify("WrapperFactory", WrapperFactory.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const RewardEscrowV2 = await contractDeploy("RewardEscrowV2", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["RewardEscrowV2"] = RewardEscrowV2.address;
  // await verify("RewardEscrowV2", RewardEscrowV2.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const TradingRewards = await contractDeploy("TradingRewards", [
  //   deployer,
  //   deployer, // periodController
  //   deployments["AddressResolver"],
  // ]);
  // deployments["TradingRewards"] = TradingRewards.address;
  // await verify("TradingRewards", TradingRewards.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const DirectIntegrationManager = await contractDeploy(
  //   "DirectIntegrationManager",
  //   [deployer, deployments["AddressResolver"]]
  // );
  // deployments["DirectIntegrationManager"] = DirectIntegrationManager.address;
  // await verify("DirectIntegrationManager", DirectIntegrationManager.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SynDex = await contractDeploy("SynDex", [
  //   deployments["ProxySFCX"],
  //   deployments["TokenStateSFCX"],
  //   deployer,
  //   0,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynDex"] = SynDex.address;
  // await verify("SynDex", SynDex.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const FeePool = await contractDeploy(
  //   "FeePool",
  //   [deployments["ProxycfUSD"], deployer, deployments["AddressResolver"]],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //     },
  //   }
  // );
  // deployments["FeePool"] = FeePool.address;
  // await verify("FeePool", FeePool.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const FeePoolEternalStorage = await contractDeploy("FeePoolEternalStorage", [
  //   deployer,
  //   deployments["FeePool"],
  // ]);
  // deployments["FeePoolEternalStorage"] = FeePoolEternalStorage.address;
  // await verify("FeePoolEternalStorage", FeePoolEternalStorage.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const RewardEscrow = await contractDeploy(contractsPath.RewardEscrow, [
  //   deployer,
  //   deployments["SynDex"],
  //   deployments["FeePool"],
  // ]);
  // deployments["RewardEscrow"] = RewardEscrow.address;
  // await verify(contractsPath.RewardEscrow, RewardEscrow.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const EtherWrapper = await contractDeploy(
  //   "EtherWrapper",
  //   [deployer, deployments["AddressResolver"], deployments["WETH"]],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //     },
  //   }
  // );
  // deployments["EtherWrapper"] = EtherWrapper.address;
  // await verify("EtherWrapper", EtherWrapper.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const FuturesMarketManager = await contractDeploy("FuturesMarketManager", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["FuturesMarketManager"] = FuturesMarketManager.address;
  // await verify("FuturesMarketManager", FuturesMarketManager.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const LiquidatorRewards = await contractDeploy("LiquidatorRewards", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["LiquidatorRewards"] = LiquidatorRewards.address;
  // await verify("LiquidatorRewards", LiquidatorRewards.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SynDexDebtShare = await contractDeploy("SynDexDebtShare", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynDexDebtShare"] = SynDexDebtShare.address;
  // await verify("SynDexDebtShare", SynDexDebtShare.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SynthcfUSD = await contractDeploy("MultiCollateralSynth", [
  //   deployments["ProxycfUSD"],
  //   deployments["TokenStatecfUSD"],
  //   "SynthcfUSD",
  //   "cfUSD",
  //   deployer,
  //   ethers.utils.formatBytes32String("cfUSD"),
  //   0,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynthcfUSD"] = SynthcfUSD.address;
  // await verify("MultiCollateralSynth", SynthcfUSD.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SynthcfETH = await contractDeploy("MultiCollateralSynth", [
  //   deployments["ProxycfETH"],
  //   deployments["TokenStatecfETH"],
  //   "SynthcfETH",
  //   "cfETH",
  //   deployer,
  //   ethers.utils.formatBytes32String("cfETH"),
  //   0,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynthcfETH"] = SynthcfETH.address;
  // await verify("MultiCollateralSynth", SynthcfETH.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const RewardEscrowV2Storage = await contractDeploy("RewardEscrowV2Storage", [
  //   deployer,
  //   deployments["RewardEscrowV2"],
  // ]);
  // deployments["RewardEscrowV2Storage"] = RewardEscrowV2Storage.address;
  // await verify("RewardEscrowV2Storage", RewardEscrowV2Storage.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const RewardsDistribution = await contractDeploy("RewardsDistribution", [
  //   deployer,
  //   deployments["SynDex"],
  //   deployments["ProxySFCX"],
  //   deployments["RewardEscrowV2"],
  //   deployments["ProxyFeePool"],
  // ]);
  // deployments["RewardsDistribution"] = RewardsDistribution.address;
  // await verify("RewardsDistribution", RewardsDistribution.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const RewardEscrowV2Frozen = await contractDeploy("RewardEscrowV2Frozen", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["RewardEscrowV2Frozen"] = RewardEscrowV2Frozen.address;
  // await verify("RewardEscrowV2Frozen", RewardEscrowV2Frozen.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const EternalStorage = await contractDeploy("EternalStorage", [
  //   deployer,
  //   deployments["SynthcfUSD"],
  // ]);
  // deployments["EternalStorage"] = EternalStorage.address;
  // await verify("EternalStorage", EternalStorage.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const DelegateApprovals = await contractDeploy("DelegateApprovals", [
  //   deployer,
  //   deployments["EternalStorage"],
  // ]);
  // deployments["DelegateApprovals"] = DelegateApprovals.address;
  // await verify("DelegateApprovals", DelegateApprovals.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const ExchangeRates = await contractDeploy(
  //   "ExchangeRates",
  //   [deployer, deployments["AddressResolver"]],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //     },
  //   }
  // );
  // deployments["ExchangeRates"] = ExchangeRates.address;
  // await verify("ExchangeRates", ExchangeRates.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const AggregatorSynth = await contractDeploy("AggregatorSynth", [
  //   "",
  //   1 * 10 ** 8,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["AggregatorSynth"] = AggregatorSynth.address;
  // await verify("AggregatorSynth", AggregatorSynth.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const AggregatorETH = await contractDeploy("AggregatorETH", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["AggregatorETH"] = AggregatorETH.address;
  // await verify("AggregatorETH", AggregatorETH.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const AggregatorCollateral = await contractDeploy("AggregatorCollateral", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["AggregatorCollateral"] = AggregatorCollateral.address;
  // await verify("AggregatorCollateral", AggregatorCollateral.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const AggregatorIssuedSynths = await contractDeploy(
  //   "AggregatorIssuedSynths",
  //   [deployments["AddressResolver"]]
  // );
  // deployments["AggregatorIssuedSynths"] = AggregatorIssuedSynths.address;
  // await verify("AggregatorIssuedSynths", AggregatorIssuedSynths.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const AggregatorDebtRatio = await contractDeploy("AggregatorDebtRatio", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["AggregatorDebtRatio"] = AggregatorDebtRatio.address;
  // await verify("AggregatorDebtRatio", AggregatorDebtRatio.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const Staking = await contractDeploy("Staking", [
  //   deployments["ProxySFCX"],
  //   deployments["ProxySFCX"],
  // ]);
  // deployments["Staking"] = Staking.address;
  // await verify("Staking", Staking.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const TestToken = await contractDeploy("Token", [
  //   "TestToken",
  //   "TKN",
  //   deployer,
  //   parseEth(1000000),
  // ]);
  // deployments["TestToken"] = TestToken.address;
  // await verify("Token", TestToken.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const FactoryContract = new ethers.Contract(
  //   deployments["UniswapFactory"],
  //   uniswapFactory,
  //   signer
  // );

  // await FactoryContract.createPair(
  //   deployments["ProxySFCX"],
  //   deployments["WETH"]
  // );
  // deployments["SFCXWETH"] = await FactoryContract.getPair(
  //   deployments["ProxySFCX"],
  //   deployments["WETH"]
  // );
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // await FactoryContract.createPair(
  //   deployments["TestToken"],
  //   deployments["ProxycfUSD"]
  // );
  // deployments["TKNUSD"] = await FactoryContract.getPair(
  //   deployments["TestToken"],
  //   deployments["ProxycfUSD"]
  // );
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // // ============================================================ //

  console.log("--- DEPLOYMENTS UPDATED ---");

  // // ============================================================ //

  // ! ------------------------------------------------------------------------
  // ! RESOLVER ADDRESSES -----------------------------------------------------
  // ! ------------------------------------------------------------------------

  // let count = 0;
  // let names = [];
  // let addresses = [];

  // names.push(ethers.utils.formatBytes32String("AddressResolver"));
  // addresses.push(deployments["AddressResolver"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("ProxySFCX"));
  // addresses.push(deployments["ProxySFCX"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("SystemStatus"));
  // addresses.push(deployments["SystemStatus"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("TokenStateSFCX"));
  // addresses.push(deployments["TokenStateSFCX"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("TokenStatecfUSD"));
  // addresses.push(deployments["TokenStatecfUSD"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("ext:AggregatorIssuedSynths"));
  // addresses.push(deployments["AggregatorIssuedSynths"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("ext:AggregatorDebtRatio"));
  // addresses.push(deployments["AggregatorDebtRatio"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("FlexibleStorage"));
  // addresses.push(deployments["FlexibleStorage"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("ExchangeState"));
  // addresses.push(deployments["ExchangeState"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("DelegateApprovals"));
  // addresses.push(deployments["DelegateApprovals"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("RewardsDistribution"));
  // addresses.push(deployments["RewardsDistribution"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("RewardEscrowV2Storage"));
  // addresses.push(deployments["RewardEscrowV2Storage"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("RewardEscrow"));
  // addresses.push(deployments["RewardEscrow"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("FeePoolEternalStorage"));
  // addresses.push(deployments["FeePoolEternalStorage"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("SynDexBridgeToOptimism"));
  // addresses.push(deployer);
  // count++;
  // // ---------------------------------------------
  // names.push(ethers.utils.formatBytes32String("Depot"));
  // addresses.push(deployments["Depot"]);
  // names.push(ethers.utils.formatBytes32String("DirectIntegrationManager"));
  // addresses.push(deployments["DirectIntegrationManager"]);
  // names.push(ethers.utils.formatBytes32String("RewardEscrowV2"));
  // addresses.push(deployments["RewardEscrowV2"]);
  // names.push(ethers.utils.formatBytes32String("ExchangeRates"));
  // addresses.push(deployments["ExchangeRates"]);
  // names.push(ethers.utils.formatBytes32String("Issuer"));
  // addresses.push(deployments["Issuer"]);
  // names.push(ethers.utils.formatBytes32String("LiquidatorRewards"));
  // addresses.push(deployments["LiquidatorRewards"]);
  // names.push(ethers.utils.formatBytes32String("SynDexDebtShare"));
  // addresses.push(deployments["SynDexDebtShare"]);
  // names.push(ethers.utils.formatBytes32String("SynDex"));
  // addresses.push(deployments["SynDex"]);
  // names.push(ethers.utils.formatBytes32String("SynthcfUSD"));
  // addresses.push(deployments["SynthcfUSD"]);
  // names.push(ethers.utils.formatBytes32String("SynthcfETH"));
  // addresses.push(deployments["SynthcfETH"]);
  // names.push(ethers.utils.formatBytes32String("FeePool"));
  // addresses.push(deployments["FeePool"]);
  // names.push(ethers.utils.formatBytes32String("DebtCache"));
  // addresses.push(deployments["DebtCache"]);
  // names.push(ethers.utils.formatBytes32String("CircuitBreaker"));
  // addresses.push(deployments["CircuitBreaker"]);
  // names.push(ethers.utils.formatBytes32String("SystemSettings"));
  // addresses.push(deployments["SystemSettings"]);
  // names.push(ethers.utils.formatBytes32String("Exchanger"));
  // addresses.push(deployments["Exchanger"]);
  // names.push(ethers.utils.formatBytes32String("Liquidator"));
  // addresses.push(deployments["Liquidator"]);
  // names.push(ethers.utils.formatBytes32String("SynthRedeemer"));
  // addresses.push(deployments["SynthRedeemer"]);
  // names.push(ethers.utils.formatBytes32String("CollateralManager"));
  // addresses.push(deployments["CollateralManager"]);
  // names.push(ethers.utils.formatBytes32String("CollateralEth"));
  // addresses.push(deployments["CollateralEth"]);
  // names.push(ethers.utils.formatBytes32String("CollateralUtil"));
  // addresses.push(deployments["CollateralUtil"]);
  // names.push(ethers.utils.formatBytes32String("FuturesMarketManager"));
  // addresses.push(deployments["FuturesMarketManager"]);
  // names.push(ethers.utils.formatBytes32String("EtherWrapper"));
  // addresses.push(deployments["EtherWrapper"]);
  // names.push(ethers.utils.formatBytes32String("WrapperFactory"));
  // addresses.push(deployments["WrapperFactory"]);
  // names.push(ethers.utils.formatBytes32String("TradingRewards"));
  // addresses.push(deployments["TradingRewards"]);

  // const addressResolver = await ethers.getContractAt(
  //   contractsPath.AddressResolver,
  //   deployments["AddressResolver"],
  //   signer
  // );
  // await addressResolver.loadAddresses(names, addresses);

  // const abi = ["function refreshCache() public"];
  // for (let i = count; i < addresses.length; i++) {
  //   console.log(i);
  //   const contract = new ethers.Contract(addresses[i], abi, signer);
  //   await contract.refreshCache();
  // }

  // ! ------------------------------------------------------------------------
  // ! SETUP ------------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  // let synthNamesInResolver = [];
  // let synthKeys = [];
  // synthNamesInResolver.push(ethers.utils.formatBytes32String("SynthcfUSD"));
  // synthKeys.push(ethers.utils.formatBytes32String("cfUSD"));
  // synthNamesInResolver.push(ethers.utils.formatBytes32String("SynthcfETH"));
  // synthKeys.push(ethers.utils.formatBytes32String("cfETH"));

  // const collateralETH = await ethers.getContractAt(
  //   contractsPath.CollateralETH,
  //   deployments["CollateralEth"],
  //   signer
  // );

  // await collateralETH.addSynths(synthNamesInResolver, synthKeys);

  // const collateralManager = await ethers.getContractAt(
  //   contractsPath.CollateralManager,
  //   deployments["CollateralManager"],
  //   signer
  // );

  // await collateralManager.addSynths(synthNamesInResolver, synthKeys);
  // await collateralManager.addCollaterals([deployments["CollateralEth"]]);

  // const issuer = await ethers.getContractAt(
  //   contractsPath.Issuer,
  //   deployments["Issuer"],
  //   signer
  // );
  // await issuer.addSynth(deployments["SynthcfUSD"]);
  // await issuer.addSynth(deployments["SynthcfETH"]);

  // const proxySFCX = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxySFCX"],
  //   signer
  // );
  // await proxySFCX.updateTarget(deployments["SynDex"]);

  // const proxycfUSD = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxycfUSD"],
  //   signer
  // );
  // await proxycfUSD.updateTarget(deployments["SynthcfUSD"]);

  // const proxycfETH = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxycfETH"],
  //   signer
  // );
  // await proxycfETH.updateTarget(deployments["SynthcfETH"]);

  // const proxyFeePool = await ethers.getContractAt(
  //   contractsPath.Proxy,
  //   deployments["ProxyFeePool"],
  //   signer
  // );
  // await proxyFeePool.updateTarget(deployments["FeePool"]);

  // const syndexState = await ethers.getContractAt(
  //   contractsPath.SynDexState,
  //   deployments["SynDexState"],
  //   signer
  // );
  // await syndexState.linkContract(deployments["SynDex"]);

  // const tokenStateSFCX = await ethers.getContractAt(
  //   contractsPath.TokenState,
  //   deployments["TokenStateSFCX"],
  //   signer
  // );
  // await tokenStateSFCX.linkContract(deployments["SynDex"]);

  // const tokenStatecfUSD = await ethers.getContractAt(
  //   contractsPath.TokenState,
  //   deployments["TokenStatecfUSD"],
  //   signer
  // );
  // await tokenStatecfUSD.linkContract(deployments["SynthcfUSD"]);

  // const tokenStatecfETH = await ethers.getContractAt(
  //   contractsPath.TokenState,
  //   deployments["TokenStatecfETH"],
  //   signer
  // );
  // await tokenStatecfETH.linkContract(deployments["SynthcfETH"]);

  // const collateralManagerState = await ethers.getContractAt(
  //   contractsPath.CollateralManagerState,
  //   deployments["CollateralManagerState"],
  //   signer
  // );
  // await collateralManagerState.linkContract(
  //   deployments["CollateralManager"]
  // );

  // const rewardEscrowV2Storage = await ethers.getContractAt(
  //   contractsPath.RewardEscrowV2Storage,
  //   deployments["RewardEscrowV2Storage"],
  //   signer
  // );
  // await rewardEscrowV2Storage.setFallbackRewardEscrow(
  //   deployments["RewardEscrowV2Frozen"]
  // );

  // const exchangeRates = await ethers.getContractAt(
  //   contractsPath.ExchangeRates,
  //   deployments["ExchangeRates"],
  //   signer
  // );
  // await exchangeRates.addAggregator(
  //   ethers.utils.formatBytes32String("SFCX"),
  //   deployments["AggregatorCollateral"]
  // );
  // await exchangeRates.addAggregator(
  //   ethers.utils.formatBytes32String("cfETH"),
  //   deployments["AggregatorSynth"]
  // );
  // // await exchangeRates.addAggregator(
  // //   ethers.utils.formatBytes32String("TKN"),
  // //   deployments["AggregatorETH"] // aggregatorSynth
  // // );

  // const systemSettings = await ethers.getContractAt(
  //   contractsPath.SystemSettings,
  //   deployments["SystemSettings"],
  //   signer
  // );

  // let synthKeys = [];
  // let exchangeFeeRates = [];
  // synthKeys.push(ethers.utils.formatBytes32String("cfUSD"));
  // synthKeys.push(ethers.utils.formatBytes32String("cfETH"));
  // exchangeFeeRates.push(parseEth(0.001));
  // exchangeFeeRates.push(parseEth(0.001)); // 0.0035
  // await systemSettings.updateExchangeFeeRateForSynths(synthKeys, exchangeFeeRates);

  // await systemSettings.setIssuanceRatio(parseEth(0.2));
  // await systemSettings.setLiquidationRatio(parseEth(0.625));
  // await systemSettings.updateSnxLiquidationPenalty(parseEth(0.6)); // forced
  // await systemSettings.updateSelfLiquidationPenalty(parseEth(0.5));
  // await systemSettings.updateLiquidationDelay(28800);
  // await systemSettings.updateRateStalePeriod(86400);
  // await systemSettings.updatePriceDeviationThreshold(parseEth(100));

  // await systemSettings.updateAtomicTwapWindow(1800);
  // await systemSettings.updateAtomicMaxVolumePerBlock(parseEth(200000));
  // await systemSettings.updateExchangeMaxDynamicFee(parseEth(0.1));
  // await systemSettings.updateExchangeDynamicFeeRounds(6);
  // await systemSettings.updateExchangeDynamicFeeThreshold(parseEth(0.0025));
  // await systemSettings.updateExchangeDynamicFeeWeightDecay(parseEth(0.95));
  // await systemSettings.updatePriceDeviationThreshold(parseEth(3));
  // await systemSettings.toggleTradingRewards(true);
  // await systemSettings.setFeePeriodDuration(604800);

  // const syndex = await ethers.getContractAt(
  //   contractsPath.SynDex,
  //   deployments["SynDex"],
  //   signer
  // );
  // const proxySFCX = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxySFCX"],
  //   signer
  // );

  // await syndex.mint(deployer, parseEth(1000000));
  // await syndex.setReserveAddress(reserveAddr);
  // await syndex.setPool(deployments["SFCXWETH"], true);
  // await syndex.setTrade(true);

  // await proxySFCX.transfer(user1, parseEth(1000));
  // await proxySFCX.transfer(user2, parseEth(1000));
  // await proxySFCX.transfer(reserveAddr, parseEth(200000));

  // await syndex.createSynths(parseEth(300));

  // // await syndex.createMaxSynths();
  // // await syndex.executeExchange(
  // //   ethers.utils.formatBytes32String("cfUSD"),
  // //   parseEth(50),
  // //   ethers.utils.formatBytes32String("cfETH")
  // // );

  // const RouterContract = new ethers.Contract(
  //   deployments["UniswapRouter"],
  //   uniswapRouter,
  //   signer
  // );
  // const proxycfUSD = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxycfUSD"],
  //   signer
  // );
  // const testToken = await ethers.getContractAt(
  //   contractsPath.TestToken,
  //   deployments["TestToken"],
  //   signer
  // );

  // await proxycfUSD.approve(deployments["UniswapRouter"], parseEth(100));
  // await testToken.approve(deployments["UniswapRouter"], parseEth(100));
  // await RouterContract.addLiquidity(
  //   deployments["ProxycfUSD"],
  //   deployments["TestToken"],
  //   parseEth(100),
  //   parseEth(100),
  //   1,
  //   1,
  //   deployer,
  //   Math.round(Date.now() / 1000) + 1000
  // );

  // // await proxycfUSD.approve(deployments["UniswapRouter"], parseEth(50));
  // // await proxycfETH.approve(deployments["UniswapRouter"], parseEth(50));
  // // await RouterContract.addLiquidity(
  // //   deployments["ProxycfUSD"],
  // //   deployments["ProxycfETH"],
  // //   parseEth(50),
  // //   parseEth(50),
  // //   1,
  // //   1,
  // //   deployer,
  // //   Math.round(Date.now() / 1000) + 1000
  // // );
  // console.log("ADDED LIQUIDITY");

  // ! ------------------------------------------------------------
  // await addSynths();
  // ! ------------------------------------------------------------

  // ! ------------------------------------------------------------
  // await uniswapV3();
  // ! ------------------------------------------------------------

  // ! ------------------------------------------------------------
  // await removeLiquidityV2(
  //   deployments["ProxycfUSD"],
  //   deployments["ProxycfETH"],
  //   parseEth(10),
  //   0,
  //   0,
  //   Math.floor(Date.now() / 1000) + 60 * 20 // 20 minutes from the current Unix time
  // );
  // ! ------------------------------------------------------------

  // ! ------------------------------------------------------------
  // await getPositions();

  // const tokenId = 701434; // Replace with your NFT position ID
  // const liquidity = parseEth(25); // Replace with the amount of liquidity to remove
  // const amount0Min = 0;
  // const amount1Min = 0;
  // const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20 minutes from the current Unix time

  // await removeLiquidityV3(tokenId, liquidity, amount0Min, amount1Min, deadline);
  // ! ------------------------------------------------------------

  console.log("[[[ COMPLETED ]]]");
}

async function getPositions() {
  const positionManager = new ethers.Contract(
    deployments["NonfungiblePositionManager"],
    uniswapNonfungiblePositionManager,
    signer
  );

  try {
    // Get the balance of NFTs for the wallet
    const balance = await positionManager.balanceOf(deployer);
    console.log(`NFT balance: ${balance.toString()}`);

    // Fetch each NFT position ID
    for (let i = 0; i < balance; i++) {
      const tokenId = await positionManager.tokenOfOwnerByIndex(deployer, i);
      console.log(`Position ID: ${tokenId.toString()}`);
    }
  } catch (error) {
    console.error("Error fetching positions:", error);
  }
}

async function removeLiquidityV3(
  tokenId,
  liquidity,
  amount0Min,
  amount1Min,
  deadline
) {
  const positionManager = new ethers.Contract(
    deployments["NonfungiblePositionManager"],
    uniswapNonfungiblePositionManager,
    signer
  );

  try {
    const tx = await positionManager.decreaseLiquidity({
      tokenId,
      liquidity,
      amount0Min,
      amount1Min,
      deadline,
    });

    console.log("Transaction hash:", tx.hash);
    await tx.wait();
    console.log("Liquidity removed successfully");

    const collectTx = await positionManager.collect({
      tokenId,
      recipient: deployer,
      amount0Max: parseEth(1000000), // ethers.constants.MaxUint128
      amount1Max: parseEth(1000000), // ethers.constants.MaxUint128
    });

    console.log("Collect transaction hash:", collectTx.hash);
    await collectTx.wait();
    console.log("Fees collected successfully");
  } catch (error) {
    console.error("Error removing liquidity:", error);
  }
}

async function removeLiquidityV2(
  tokenA,
  tokenB,
  liquidity,
  amountAMin,
  amountBMin,
  deadline
) {
  let pair = new ethers.Contract(deployments["ETHUSD"], uniswapPair, signer);
  console.log(await pair.getReserves());

  const RouterContract = new ethers.Contract(
    deployments["UniswapRouter"],
    uniswapRouter,
    signer
  );
  try {
    const tx = await RouterContract.removeLiquidity(
      tokenA,
      tokenB,
      liquidity,
      amountAMin,
      amountBMin,
      deployer,
      deadline
    );

    console.log("Transaction hash:", tx.hash);
    await tx.wait();
    console.log("Liquidity removed successfully");
  } catch (error) {
    console.error("Error removing liquidity:", error);
  }
}

async function uniswapV3() {
  // const FactoryContract = new ethers.Contract(
  //   deployments["UniswapFactoryV3"],
  //   uniswapFactoryV3,
  //   signer
  // );

  // await FactoryContract.createPool(
  //   deployments["ProxycfUSD"],
  //   deployments["TestToken"],
  //   3000
  // );
  // deployments["TKNUSDV3"] = await FactoryContract.getPool(
  //   deployments["ProxycfUSD"],
  //   deployments["TestToken"],
  //   3000
  // );
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const v3Pool = new ethers.Contract(
  //   deployments["TKNUSDV3"],
  //   uniswapPoolV3,
  //   signer
  // );
  // await v3Pool.initialize(79228162514264337593543950336n);

  // // console.log("=== POOL CREATED ===");

  const proxycfUSD = await ethers.getContractAt(
    contractsPath.ProxyERC20,
    deployments["ProxycfUSD"],
    signer
  );
  let balanceOfcfUSD = await proxycfUSD.balanceOf(deployer);
  console.log("balanceOfcfUSD", balanceOfcfUSD);
  // await proxycfUSD.approve(
  //   deployments["NonfungiblePositionManager"],
  //   parseEth(50)
  // );

  const token = await ethers.getContractAt(
    contractsPath.ERC20,
    deployments["TestToken"],
    signer
  );
  let balanceOfTKN = await token.balanceOf(deployer);
  console.log("balanceOfTKN", balanceOfTKN);
  // await token.approve(
  //   deployments["NonfungiblePositionManager"],
  //   parseEth(50)
  // );

  // const params = {
  //   token0: deployments["ProxycfUSD"],
  //   token1: deployments["TestToken"],
  //   fee: v3Pool.fee(),
  //   tickLower: -120,
  //   tickUpper: 120,
  //   amount0Desired: parseEth(18),
  //   amount1Desired: parseEth(18),
  //   amount0Min: 0,
  //   amount1Min: 0,
  //   recipient: deployer,
  //   deadline: parseInt(new Date().getTime() / 1000) + 600,
  // };
  // const nonfungiblePositionManager = new ethers.Contract(
  //   deployments["NonfungiblePositionManager"],
  //   uniswapNonfungiblePositionManager,
  //   signer
  // );
  // await nonfungiblePositionManager.mint(params);

  // // console.log("--- ADDED LIQUIDITY ---");
}

async function addSynths() {
  // cfGold | cfWheat | Crude Oil | Orange Juice | cfSilver | cfPlatinum | cfPalladium | cfLivestock
  // cfCoffee | cfSugar | cfCotton | cfSoybeans | Natural Gas | cfIron | cfCocoa | cfSteel | cfCopper
  // await deploySynth(
  //   "ProxycfGold",
  //   "SynthcfGold",
  //   "cfGold",
  //   "TokenStatecfGold",
  //   "AggregatorcfGold",
  //   2344 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfWheat",
  //   "SynthcfWheat",
  //   "cfWheat",
  //   "TokenStatecfWheat",
  //   "AggregatorcfWheat",
  //   729 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfCrudeOil",
  //   "SynthcfCrudeOil",
  //   "cfCrudeOil",
  //   "TokenStatecfCrudeOil",
  //   "AggregatorcfCrudeOil",
  //   79 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfOrangeJuice",
  //   "SynthcfOrangeJuice",
  //   "cfOrangeJuice",
  //   "TokenStatecfOrangeJuice",
  //   "AggregatorcfOrangeJuice",
  //   477 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfSilver",
  //   "SynthcfSilver",
  //   "cfSilver",
  //   "TokenStatecfSilver",
  //   "AggregatorcfSilver",
  //   32 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfPlatinum",
  //   "SynthcfPlatinum",
  //   "cfPlatinum",
  //   "TokenStatecfPlatinum",
  //   "AggregatorcfPlatinum",
  //   1046 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfPalladium",
  //   "SynthcfPalladium",
  //   "cfPalladium",
  //   "TokenStatecfPalladium",
  //   "AggregatorcfPalladium",
  //   957 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfLivestock",
  //   "SynthcfLivestock",
  //   "cfLivestock",
  //   "TokenStatecfLivestock",
  //   "AggregatorcfLivestock",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfCoffee",
  //   "SynthcfCoffee",
  //   "cfCoffee",
  //   "TokenStatecfCoffee",
  //   "AggregatorcfCoffee",
  //   233 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfSugar",
  //   "SynthcfSugar",
  //   "cfSugar",
  //   "TokenStatecfSugar",
  //   "AggregatorcfSugar",
  //   18 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfCotton",
  //   "SynthcfCotton",
  //   "cfCotton",
  //   "TokenStatecfCotton",
  //   "AggregatorcfCotton",
  //   81 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfSoybeans",
  //   "SynthcfSoybeans",
  //   "cfSoybeans",
  //   "TokenStatecfSoybeans",
  //   "AggregatorcfSoybeans",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfNaturalGas",
  //   "SynthcfNaturalGas",
  //   "cfNaturalGas",
  //   "TokenStatecfNaturalGas",
  //   "AggregatorcfNaturalGas",
  //   2.456 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfIron",
  //   "SynthcfIron",
  //   "cfIron",
  //   "TokenStatecfIron",
  //   "AggregatorcfIron",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfCocoa",
  //   "SynthcfCocoa",
  //   "cfCocoa",
  //   "TokenStatecfCocoa",
  //   "AggregatorcfCocoa",
  //   9423 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfSteel",
  //   "SynthcfSteel",
  //   "cfSteel",
  //   "TokenStatecfSteel",
  //   "AggregatorcfSteel",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxycfCopper",
  //   "SynthcfCopper",
  //   "cfCopper",
  //   "TokenStatecfCopper",
  //   "AggregatorcfCopper",
  //   4.7835 * 10 ** 8
  // );
}

async function deploySynth(
  proxyName,
  synthName,
  synthSymbol,
  tokenStateName,
  aggregatorName,
  synthPrice
) {
  const Aggregator = await contractDeploy("AggregatorSynth", [
    aggregatorName,
    synthPrice,
    deployments["AddressResolver"],
  ]);
  deployments[aggregatorName] = Aggregator.address;
  await verify("AggregatorSynth", Aggregator.address);
  writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  const Proxy = await contractDeploy("ProxyERC20", [deployer]);
  deployments[proxyName] = Proxy.address;
  await verify("ProxyERC20", Proxy.address);
  writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  const TokenState = await contractDeploy("TokenState", [
    deployer,
    ADDRESS_ZERO, // Synth
  ]);
  deployments[tokenStateName] = TokenState.address;
  await verify("TokenState", TokenState.address);
  writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  const Synth = await contractDeploy("MultiCollateralSynth", [
    deployments[proxyName],
    deployments[tokenStateName],
    synthName,
    synthSymbol,
    deployer,
    ethers.utils.formatBytes32String(synthSymbol),
    0,
    deployments["AddressResolver"],
  ]);
  deployments[synthName] = Synth.address;
  await verify("MultiCollateralSynth", Synth.address);
  writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  console.log("=== DEPLOYMENTS ===");

  // ! ---

  let names = [];
  let addresses = [];
  names.push(ethers.utils.formatBytes32String(synthName));
  addresses.push(deployments[synthName]);

  const addressResolver = await ethers.getContractAt(
    contractsPath.AddressResolver,
    deployments["AddressResolver"],
    signer
  );
  await addressResolver.loadAddresses(names, addresses);

  console.log("=== IMPORT ADDRESSES ===");

  const abi = ["function refreshCache() public"];
  const contract = new ethers.Contract(deployments[synthName], abi, signer);
  await contract.refreshCache();

  console.log("=== REBUILD CACHE ===");

  // ! ---

  let synthNamesInResolver = [];
  let synthKeys = [];
  synthNamesInResolver.push(ethers.utils.formatBytes32String(synthName));
  synthKeys.push(ethers.utils.formatBytes32String(synthSymbol));

  const collateralETH = await ethers.getContractAt(
    contractsPath.CollateralETH,
    deployments["CollateralEth"],
    signer
  );
  await collateralETH.addSynths(synthNamesInResolver, synthKeys);

  console.log("=== collateralETH.addSynths ===");

  const collateralManager = await ethers.getContractAt(
    contractsPath.CollateralManager,
    deployments["CollateralManager"],
    signer
  );
  await collateralManager.addSynths(synthNamesInResolver, synthKeys);

  console.log("=== collateralManager.addSynths ===");

  // ! ---

  const issuer = await ethers.getContractAt(
    contractsPath.Issuer,
    deployments["Issuer"],
    signer
  );
  await issuer.addSynth(deployments[synthName]);

  const proxy = await ethers.getContractAt(
    contractsPath.ProxyERC20,
    deployments[proxyName],
    signer
  );
  await proxy.updateTarget(deployments[synthName]);

  const tokenState = await ethers.getContractAt(
    contractsPath.TokenState,
    deployments[tokenStateName],
    signer
  );
  await tokenState.linkContract(deployments[synthName]);

  const exchangeRates = await ethers.getContractAt(
    contractsPath.ExchangeRates,
    deployments["ExchangeRates"],
    signer
  );
  await exchangeRates.addAggregator(
    ethers.utils.formatBytes32String(synthSymbol),
    deployments[aggregatorName]
  );

  console.log("=== EXCHANGE RATES ADDED ===");

  // ! ---

  let synthKey = [];
  let exchangeFeeRates = [];
  synthKey.push(ethers.utils.formatBytes32String(synthSymbol));
  exchangeFeeRates.push(parseEth(0.001));

  const systemSettings = await ethers.getContractAt(
    contractsPath.SystemSettings,
    deployments["SystemSettings"],
    signer
  );
  await systemSettings.updateExchangeFeeRateForSynths(
    synthKey,
    exchangeFeeRates
  );

  console.log("=== systemSettings.updateExchangeFeeRateForSynths ===");

  console.log(`=== ${synthSymbol} DONE ===`);
}

const contractDeploy = async (name, args, libraries) => {
  const contractFactory = await ethers.getContractFactory(name, libraries);
  const contract = await contractFactory.deploy(...args);
  await contract.deployTransaction.wait();

  console.info(`Deploying ${name} : ${contract.address}`);

  return contract;
};

const verify = async (name, address, libraries) => {
  console.log("Verifying contract...");
  try {
    await tenderly.verify({ name, address, libraries });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already verified!");
    } else {
      console.log(e);
    }
  }
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
