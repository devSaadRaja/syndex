const { tenderly } = require("hardhat");

const { readFileSync, writeFileSync } = require("fs");

var url, chainId, outputFilePath;
const option = Number(process.env.TENDERLY_MAIN_OPTION);
if (option == 1) {
  url = process.env.TENDERLY_MAINNET_FORK_URL_TEST;
  outputFilePath = "./test_tenderly_deployments.json";
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
  Synthetix: "src/contracts/Synthetix.sol:Synthetix",
  Exchanger: "src/contracts/Exchanger.sol:Exchanger",
  ProxyERC20: "src/contracts/ProxyERC20.sol:ProxyERC20",
  TokenState: "src/contracts/TokenState.sol:TokenState",
  RewardEscrow: "src/contracts/RewardEscrow.sol:RewardEscrow",
  ExchangeRates: "src/contracts/ExchangeRates.sol:ExchangeRates",
  CollateralETH: "src/contracts/CollateralEth.sol:CollateralEth",
  SystemSettings: "src/contracts/SystemSettings.sol:SystemSettings",
  SupplySchedule: "src/contracts/SupplySchedule.sol:SupplySchedule",
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

const deployer = "0xE536B4D7cf1e346D985cEe807e16B1b11B019976";
const user = "0xc5Fa3B9D1C223E96eC77CB48880eeBeb9DaB4ad7";
const treasury = "0x35D9466FFa2497fa919203809C2F150F493A0f73";

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

  // const CollateralEth = await contractDeploy("CollateralEth", [
  //   deployer,
  //   deployments["CollateralManager"],
  //   deployments["AddressResolver"],
  //   ethers.utils.formatBytes32String("sETH"),
  //   parseEth(1.5), // 100 / 150, 150%
  //   parseEth(0.1),
  // ]);
  // deployments["CollateralEth"] = CollateralEth.address;
  // await verify("CollateralEth", CollateralEth.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const ProxySNX = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxySNX"] = ProxySNX.address;
  // await verify("ProxyERC20", ProxySNX.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const ProxysUSD = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxysUSD"] = ProxysUSD.address;
  // await verify("ProxyERC20", ProxysUSD.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const ProxysETH = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxysETH"] = ProxysETH.address;
  // await verify("ProxyERC20", ProxysETH.address);
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

  // const TokenStateSNX = await contractDeploy("LegacyTokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // synthetix
  // ]);
  // deployments["TokenStateSNX"] = TokenStateSNX.address;
  // await verify("LegacyTokenState", TokenStateSNX.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const TokenStatesUSD = await contractDeploy("TokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // synthsUSD
  // ]);
  // deployments["TokenStatesUSD"] = TokenStatesUSD.address;
  // await verify("TokenState", TokenStatesUSD.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const TokenStatesETH = await contractDeploy("TokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // synthsETH
  // ]);
  // deployments["TokenStatesETH"] = TokenStatesETH.address;
  // await verify("TokenState", TokenStatesETH.address);
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

  // const SupplySchedule = await contractDeploy(contractsPath.SupplySchedule, [
  //   deployer,
  //   1551830400,
  //   4,
  // ]);
  // deployments["SupplySchedule"] = SupplySchedule.address;
  // await verify(contractsPath.SupplySchedule, SupplySchedule.address);
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

  // const Synthetix = await contractDeploy("Synthetix", [
  //   deployments["ProxySNX"],
  //   deployments["TokenStateSNX"],
  //   deployer,
  //   0,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["Synthetix"] = Synthetix.address;
  // await verify("Synthetix", Synthetix.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const FeePool = await contractDeploy(
  //   "FeePool",
  //   [deployments["ProxysUSD"], deployer, deployments["AddressResolver"]],
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
  //   deployments["Synthetix"],
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

  // const SynthetixDebtShare = await contractDeploy("SynthetixDebtShare", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynthetixDebtShare"] = SynthetixDebtShare.address;
  // await verify("SynthetixDebtShare", SynthetixDebtShare.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SynthsUSD = await contractDeploy("MultiCollateralSynth", [
  //   deployments["ProxysUSD"],
  //   deployments["TokenStatesUSD"],
  //   "SynthsUSD",
  //   "sUSD",
  //   deployer,
  //   ethers.utils.formatBytes32String("sUSD"),
  //   0,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynthsUSD"] = SynthsUSD.address;
  // await verify("MultiCollateralSynth", SynthsUSD.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SynthsETH = await contractDeploy("MultiCollateralSynth", [
  //   deployments["ProxysETH"],
  //   deployments["TokenStatesETH"],
  //   "SynthsETH",
  //   "sETH",
  //   deployer,
  //   ethers.utils.formatBytes32String("sETH"),
  //   0,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynthsETH"] = SynthsETH.address;
  // await verify("MultiCollateralSynth", SynthsETH.address);
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
  //   deployments["Synthetix"],
  //   deployments["ProxySNX"],
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
  //   deployments["SynthsUSD"],
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

  // const FactoryContract = new ethers.Contract(
  //   deployments["UniswapFactory"],
  //   uniswapFactory,
  //   signer
  // );

  // await FactoryContract.createPair(
  //   deployments["ProxysUSD"],
  //   deployments["ProxysETH"]
  // );
  // deployments["ETHUSD"] = await FactoryContract.getPair(
  //   deployments["ProxysUSD"],
  //   deployments["ProxysETH"]
  // );
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // // ============================================================ //

  console.log("--- DEPLOYMENTS UPDATED ---");

  // // ============================================================ //

  // ! ------------------------------------------------------------------------
  // ! RESOLVER ADDRESSES -----------------------------------------------------
  // ! ------------------------------------------------------------------------

  // let names = [];
  // let addresses = [];

  // names.push(ethers.utils.formatBytes32String("AddressResolver"));
  // addresses.push(deployments["AddressResolver"]);
  // names.push(ethers.utils.formatBytes32String("SystemStatus"));
  // addresses.push(deployments["SystemStatus"]);
  // names.push(ethers.utils.formatBytes32String("TokenStateSNX"));
  // addresses.push(deployments["TokenStateSNX"]);
  // names.push(ethers.utils.formatBytes32String("TokenStatesUSD"));
  // addresses.push(deployments["TokenStatesUSD"]);
  // names.push(ethers.utils.formatBytes32String("ext:AggregatorIssuedSynths"));
  // addresses.push(deployments["AggregatorIssuedSynths"]);
  // names.push(ethers.utils.formatBytes32String("ext:AggregatorDebtRatio"));
  // addresses.push(deployments["AggregatorDebtRatio"]);
  // names.push(ethers.utils.formatBytes32String("FlexibleStorage"));
  // addresses.push(deployments["FlexibleStorage"]);
  // names.push(ethers.utils.formatBytes32String("ExchangeState"));
  // addresses.push(deployments["ExchangeState"]);
  // names.push(ethers.utils.formatBytes32String("DelegateApprovals"));
  // addresses.push(deployments["DelegateApprovals"]);
  // names.push(ethers.utils.formatBytes32String("RewardsDistribution"));
  // addresses.push(deployments["RewardsDistribution"]);
  // names.push(ethers.utils.formatBytes32String("RewardEscrowV2Storage"));
  // addresses.push(deployments["RewardEscrowV2Storage"]);
  // names.push(ethers.utils.formatBytes32String("RewardEscrow"));
  // addresses.push(deployments["RewardEscrow"]);
  // names.push(ethers.utils.formatBytes32String("SupplySchedule"));
  // addresses.push(deployments["SupplySchedule"]);
  // names.push(ethers.utils.formatBytes32String("FeePoolEternalStorage"));
  // addresses.push(deployments["FeePoolEternalStorage"]);
  // // ---------------------------------------------
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
  // names.push(ethers.utils.formatBytes32String("SynthetixDebtShare"));
  // addresses.push(deployments["SynthetixDebtShare"]);
  // names.push(ethers.utils.formatBytes32String("Synthetix"));
  // addresses.push(deployments["Synthetix"]);
  // names.push(ethers.utils.formatBytes32String("SynthsUSD"));
  // addresses.push(deployments["SynthsUSD"]);
  // names.push(ethers.utils.formatBytes32String("SynthsETH"));
  // addresses.push(deployments["SynthsETH"]);
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
  // await addressResolver.importAddresses(names, addresses);

  // const abi = ["function rebuildCache() public"];
  // for (let i = 14; i < addresses.length; i++) {
  //   const contract = new ethers.Contract(addresses[i], abi, signer);
  //   await contract.rebuildCache();
  // }

  // const TestToken = await contractDeploy("Token", [
  //   "TestToken",
  //   "TKN",
  //   deployer,
  //   parseEth(1000000),
  // ]);
  // deployments["TestToken"] = TestToken.address;
  // await verify("Token", TestToken.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // ! ------------------------------------------------------------------------
  // ! SETUP ------------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  // let synthNamesInResolver = [];
  // let synthKeys = [];
  // synthNamesInResolver.push(ethers.utils.formatBytes32String("SynthsUSD"));
  // synthKeys.push(ethers.utils.formatBytes32String("sUSD"));
  // synthNamesInResolver.push(ethers.utils.formatBytes32String("SynthsETH"));
  // synthKeys.push(ethers.utils.formatBytes32String("sETH"));

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
  // await issuer.addSynth(deployments["SynthsUSD"]);
  // await issuer.addSynth(deployments["SynthsETH"]);

  // const proxySNX = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxySNX"],
  //   signer
  // );
  // await proxySNX.setTarget(deployments["Synthetix"]);

  // const proxysUSD = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxysUSD"],
  //   signer
  // );
  // await proxysUSD.setTarget(deployments["SynthsUSD"]);

  // const proxysETH = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxysETH"],
  //   signer
  // );
  // await proxysETH.setTarget(deployments["SynthsETH"]);

  // const proxyFeePool = await ethers.getContractAt(
  //   contractsPath.Proxy,
  //   deployments["ProxyFeePool"],
  //   signer
  // );
  // await proxyFeePool.setTarget(deployments["FeePool"]);

  // const synthetix = await ethers.getContractAt(
  //   contractsPath.Synthetix,
  //   deployments["Synthetix"],
  //   signer
  // );
  // await synthetix.setTokenState(deployments["TokenStateSNX"]);

  // const tokenStateSNX = await ethers.getContractAt(
  //   contractsPath.TokenState,
  //   deployments["TokenStateSNX"],
  //   signer
  // );
  // await tokenStateSNX.setAssociatedContract(deployments["Synthetix"]);
  // await tokenStateSNX.setBalanceOf(deployer, parseEth(1000));
  // await tokenStateSNX.setBalanceOf(user, parseEth(1000));
  // await tokenStateSNX.setBalanceOf(
  //   "0xAfdb49aF7e7BDE7e99589DF3831d849b7a55dE34",
  //   parseEth(1000)
  // );

  // await synthetix.issueMaxSynths();
  // await synthetix.exchange(
  //   ethers.utils.formatBytes32String("sUSD"),
  //   parseEth(50),
  //   ethers.utils.formatBytes32String("sETH")
  // );

  // const tokenStatesUSD = await ethers.getContractAt(
  //   contractsPath.TokenState,
  //   deployments["TokenStatesUSD"],
  //   signer
  // );
  // await tokenStatesUSD.setAssociatedContract(deployments["SynthsUSD"]);

  // const tokenStatesETH = await ethers.getContractAt(
  //   contractsPath.TokenState,
  //   deployments["TokenStatesETH"],
  //   signer
  // );
  // await tokenStatesETH.setAssociatedContract(deployments["SynthsETH"]);

  // const collateralManagerState = await ethers.getContractAt(
  //   contractsPath.CollateralManagerState,
  //   deployments["CollateralManagerState"],
  //   signer
  // );
  // await collateralManagerState.setAssociatedContract(
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
  //   ethers.utils.formatBytes32String("SNX"),
  //   deployments["AggregatorCollateral"]
  // );
  // await exchangeRates.addAggregator(
  //   ethers.utils.formatBytes32String("sETH"),
  //   deployments["AggregatorETH"]
  // );
  // await exchangeRates.addAggregator(
  //   ethers.utils.formatBytes32String("TKN"),
  //   deployments["AggregatorETH"]
  // );

  // const supplySchedule = await ethers.getContractAt(
  //   contractsPath.SupplySchedule,
  //   deployments["SupplySchedule"],
  //   signer
  // );
  // await supplySchedule.setSynthetixProxy(deployments["ProxySNX"]);
  // await supplySchedule.setInflationAmount(parseEth(3000000));

  // const systemSettings = await ethers.getContractAt(
  //   contractsPath.SystemSettings,
  //   deployments["SystemSettings"],
  //   signer
  // );

  // let synthKeys = [];
  // let exchangeFeeRates = [];
  // synthKeys.push(ethers.utils.formatBytes32String("sUSD"));
  // synthKeys.push(ethers.utils.formatBytes32String("sETH"));
  // exchangeFeeRates.push(1);
  // exchangeFeeRates.push(1);
  // await systemSettings.setExchangeFeeRateForSynths(synthKeys, exchangeFeeRates);

  // await systemSettings.setIssuanceRatio(parseEth(0.2));
  // await systemSettings.setLiquidationRatio(parseEth(0.625));
  // await systemSettings.setSnxLiquidationPenalty(parseEth(0.6)); // forced
  // await systemSettings.setSelfLiquidationPenalty(parseEth(0.5));
  // await systemSettings.setLiquidationDelay(28800);
  // await systemSettings.setRateStalePeriod(86400);
  // await systemSettings.setPriceDeviationThresholdFactor(parseEth(100));

  // await systemSettings.setAtomicTwapWindow(1800);
  // await systemSettings.setAtomicMaxVolumePerBlock(parseEth(200000));
  // await systemSettings.setExchangeMaxDynamicFee(parseEth(0.1));
  // await systemSettings.setExchangeDynamicFeeRounds(6);
  // await systemSettings.setExchangeDynamicFeeThreshold(parseEth(0.0025));
  // await systemSettings.setExchangeDynamicFeeWeightDecay(parseEth(0.95));
  // await systemSettings.setPriceDeviationThresholdFactor(parseEth(3));

  // const RouterContract = new ethers.Contract(
  //   deployments["UniswapRouter"],
  //   uniswapRouter,
  //   signer
  // );
  // await proxysUSD.approve(deployments["UniswapRouter"], parseEth(50));
  // await proxysETH.approve(deployments["UniswapRouter"], parseEth(50));
  // await RouterContract.addLiquidity(
  //   deployments["ProxysUSD"],
  //   deployments["ProxysETH"],
  //   parseEth(50),
  //   parseEth(50),
  //   1,
  //   1,
  //   deployer,
  //   Math.round(Date.now() / 1000) + 1000
  // );
  // console.log("ADDED LIQUIDITY");

  // ! ------------------------------------------------------------
  // await addSynths();
  // ! ------------------------------------------------------------

  // ! ------------------------------------------------------------
  // await uniswapV3();
  // ! ------------------------------------------------------------

  // ! ------------------------------------------------------------
  // await removeLiquidityV2(
  //   deployments["ProxysUSD"],
  //   deployments["ProxysETH"],
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
  //   deployments["ProxysUSD"],
  //   deployments["TestToken"],
  //   3000
  // );
  // deployments["TKNUSDV3"] = await FactoryContract.getPool(
  //   deployments["ProxysUSD"],
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

  const proxysUSD = await ethers.getContractAt(
    contractsPath.ProxyERC20,
    deployments["ProxysUSD"],
    signer
  );
  let balanceOfsUSD = await proxysUSD.balanceOf(deployer);
  console.log("balanceOfsUSD", balanceOfsUSD);
  // await proxysUSD.approve(
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
  //   token0: deployments["ProxysUSD"],
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
  // Gold | Wheat | Crude Oil | Orange Juice | Silver | Platinum | Palladium | Livestock
  // Coffee | Sugar | Cotton | Soybeans | Natural Gas | Iron | Cocoa | Steel | Copper
  // await deploySynth(
  //   "ProxyGold",
  //   "SynthGold",
  //   "Gold",
  //   "TokenStateGold",
  //   "AggregatorGold",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyWheat",
  //   "SynthWheat",
  //   "Wheat",
  //   "TokenStateWheat",
  //   "AggregatorWheat",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyCrudeOil",
  //   "SynthCrudeOil",
  //   "CrudeOil",
  //   "TokenStateCrudeOil",
  //   "AggregatorCrudeOil",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyOrangeJuice",
  //   "SynthOrangeJuice",
  //   "OrangeJuice",
  //   "TokenStateOrangeJuice",
  //   "AggregatorOrangeJuice",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxySilver",
  //   "SynthSilver",
  //   "Silver",
  //   "TokenStateSilver",
  //   "AggregatorSilver",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyPlatinum",
  //   "SynthPlatinum",
  //   "Platinum",
  //   "TokenStatePlatinum",
  //   "AggregatorPlatinum",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyPalladium",
  //   "SynthPalladium",
  //   "Palladium",
  //   "TokenStatePalladium",
  //   "AggregatorPalladium",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyLivestock",
  //   "SynthLivestock",
  //   "Livestock",
  //   "TokenStateLivestock",
  //   "AggregatorLivestock",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyCoffee",
  //   "SynthCoffee",
  //   "Coffee",
  //   "TokenStateCoffee",
  //   "AggregatorCoffee",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxySugar",
  //   "SynthSugar",
  //   "Sugar",
  //   "TokenStateSugar",
  //   "AggregatorSugar",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyCotton",
  //   "SynthCotton",
  //   "Cotton",
  //   "TokenStateCotton",
  //   "AggregatorCotton",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxySoybeans",
  //   "SynthSoybeans",
  //   "Soybeans",
  //   "TokenStateSoybeans",
  //   "AggregatorSoybeans",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyNaturalGas",
  //   "SynthNaturalGas",
  //   "NaturalGas",
  //   "TokenStateNaturalGas",
  //   "AggregatorNaturalGas",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyIron",
  //   "SynthIron",
  //   "Iron",
  //   "TokenStateIron",
  //   "AggregatorIron",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyCocoa",
  //   "SynthCocoa",
  //   "Cocoa",
  //   "TokenStateCocoa",
  //   "AggregatorCocoa",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxySteel",
  //   "SynthSteel",
  //   "Steel",
  //   "TokenStateSteel",
  //   "AggregatorSteel",
  //   1 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyCopper",
  //   "SynthCopper",
  //   "Copper",
  //   "TokenStateCopper",
  //   "AggregatorCopper",
  //   1 * 10 ** 8
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
  await addressResolver.importAddresses(names, addresses);

  console.log("=== IMPORT ADDRESSES ===");

  const abi = ["function rebuildCache() public"];
  const contract = new ethers.Contract(deployments[synthName], abi, signer);
  await contract.rebuildCache();

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
  await proxy.setTarget(deployments[synthName]);

  const tokenState = await ethers.getContractAt(
    contractsPath.TokenState,
    deployments[tokenStateName],
    signer
  );
  await tokenState.setAssociatedContract(deployments[synthName]);

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
  exchangeFeeRates.push(1);

  const systemSettings = await ethers.getContractAt(
    contractsPath.SystemSettings,
    deployments["SystemSettings"],
    signer
  );
  await systemSettings.setExchangeFeeRateForSynths(synthKey, exchangeFeeRates);

  console.log("=== systemSettings.setExchangeFeeRateForSynths ===");

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
