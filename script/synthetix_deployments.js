const { tenderly } = require("hardhat");

const { readFileSync, writeFileSync } = require("fs");
const outputFilePath =
  process.env.TENDERLY_MAIN === "true"
    ? "./smx_tenderly_deployments.json"
    : "./smx_test_tenderly_deployments.json";

const WETH = require("../abis/weth.json");
const uniswapRouter = require("../abis/uniswap-router.json");
const uniswapFactory = require("../abis/uniswap-factory.json");

const { resolve } = require("path");
const { config } = require("dotenv");

config({ path: resolve(__dirname, "./.env") });

const parseEth = (eth) => ethers.utils.parseEther(String(eth));
const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

const contractsPath = {
  Proxy: "src/contracts/Proxy.sol:Proxy",
  Issuer: "src/contracts/Issuer.sol:Issuer",
  Synthetix: "src/contracts/Synthetix.sol:Synthetix",
  ProxyERC20: "src/contracts/ProxyERC20.sol:ProxyERC20",
  TokenState: "src/contracts/TokenState.sol:TokenState",
  RewardEscrow: "src/contracts/RewardEscrow.sol:RewardEscrow",
  ExchangeRates: "src/contracts/ExchangeRates.sol:ExchangeRates",
  CollateralETH: "src/contracts/CollateralEth.sol:CollateralEth",
  SystemSettings: "src/contracts/SystemSettings.sol:SystemSettings",
  SupplySchedule: "src/contracts/SupplySchedule.sol:SupplySchedule",
  AddressResolver: "src/contracts/AddressResolver.sol:AddressResolver",
  CollateralManager: "src/contracts/CollateralManager.sol:CollateralManager",
  RewardEscrowV2Storage:
    "src/contracts/RewardEscrowV2Storage.sol:RewardEscrowV2Storage",
  CollateralManagerState:
    "src/contracts/CollateralManagerState.sol:CollateralManagerState",
};

async function main() {
  const deployments = JSON.parse(readFileSync(outputFilePath, "utf-8"));

  // * Second parameter is chainId, 1 for Ethereum mainnet
  const provider_tenderly = new ethers.providers.JsonRpcProvider(
    process.env.TENDERLY_MAIN === "true"
      ? `${process.env.TENDERLY_MAINNET_FORK_URL}`
      : `${process.env.TENDERLY_MAINNET_FORK_URL_TEST}`,
    1
  );
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider_tenderly);

  const deployer = "0xE536B4D7cf1e346D985cEe807e16B1b11B019976";
  const user = "0xc5Fa3B9D1C223E96eC77CB48880eeBeb9DaB4ad7";
  const treasury = "0x35D9466FFa2497fa919203809C2F150F493A0f73";

  // ! ------------------------------------------------------------------------
  // ! DEPLOYMENTS ------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  // const SafeDecimalMath = await contractDeploy("SafeDecimalMath", []);
  // deployments["SafeDecimalMath"] = SafeDecimalMath.address;
  // await verify("SafeDecimalMath", SafeDecimalMath.address);

  // const SystemSettingsLib = await contractDeploy("SystemSettingsLib", [], {
  //   libraries: {
  //     SafeDecimalMath: deployments["SafeDecimalMath"],
  //   },
  // });
  // deployments["SystemSettingsLib"] = SystemSettingsLib.address;
  // await verify("SystemSettingsLib", SystemSettingsLib.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });

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

  // // * ------------------------------

  // const AddressResolver = await contractDeploy("AddressResolver", [deployer]);
  // deployments["AddressResolver"] = AddressResolver.address;
  // await verify("AddressResolver", AddressResolver.address);

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

  // const CollateralManagerState = await contractDeploy(
  //   "CollateralManagerState",
  //   [
  //     deployer,
  //     ADDRESS_ZERO, // collateralManager
  //   ]
  // );
  // deployments["CollateralManagerState"] = CollateralManagerState.address;
  // await verify("CollateralManagerState", CollateralManagerState.address);

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

  // const ProxySNX = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxySNX"] = ProxySNX.address;
  // await verify("ProxyERC20", ProxySNX.address);

  // const ProxysUSD = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxysUSD"] = ProxysUSD.address;
  // await verify("ProxyERC20", ProxysUSD.address);

  // const ProxysETH = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxysETH"] = ProxysETH.address;
  // await verify("ProxyERC20", ProxysETH.address);

  // const ProxyFeePool = await contractDeploy("Proxy", [deployer]);
  // deployments["ProxyFeePool"] = ProxyFeePool.address;
  // await verify("Proxy", ProxyFeePool.address);

  // const SystemStatus = await contractDeploy("SystemStatus", [deployer]);
  // deployments["SystemStatus"] = SystemStatus.address;
  // await verify("SystemStatus", SystemStatus.address);

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

  // const DebtCache = await contractDeploy("DebtCache", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["DebtCache"] = DebtCache.address;
  // await verify("DebtCache", DebtCache.address);

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

  // const ExchangeState = await contractDeploy("ExchangeState", [
  //   deployer,
  //   deployments["Exchanger"],
  // ]);
  // deployments["ExchangeState"] = ExchangeState.address;
  // await verify("ExchangeState", ExchangeState.address);

  // const SynthRedeemer = await contractDeploy("SynthRedeemer", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynthRedeemer"] = SynthRedeemer.address;
  // await verify("SynthRedeemer", SynthRedeemer.address);

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

  // const FlexibleStorage = await contractDeploy("FlexibleStorage", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["FlexibleStorage"] = FlexibleStorage.address;
  // await verify("FlexibleStorage", FlexibleStorage.address);

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

  // const CircuitBreaker = await contractDeploy("CircuitBreaker", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["CircuitBreaker"] = CircuitBreaker.address;
  // await verify("CircuitBreaker", CircuitBreaker.address);

  // const TokenStateSNX = await contractDeploy("LegacyTokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // synthetix
  // ]);
  // deployments["TokenStateSNX"] = TokenStateSNX.address;
  // await verify("LegacyTokenState", TokenStateSNX.address);

  // const TokenStatesUSD = await contractDeploy("TokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // synthsUSD
  // ]);
  // deployments["TokenStatesUSD"] = TokenStatesUSD.address;
  // await verify("TokenState", TokenStatesUSD.address);

  // const TokenStatesETH = await contractDeploy("TokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // synthsETH
  // ]);
  // deployments["TokenStatesETH"] = TokenStatesETH.address;
  // await verify("TokenState", TokenStatesETH.address);

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

  // const RewardEscrowV2 = await contractDeploy("RewardEscrowV2", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["RewardEscrowV2"] = RewardEscrowV2.address;
  // await verify("RewardEscrowV2", RewardEscrowV2.address);

  // const SupplySchedule = await contractDeploy(contractsPath.SupplySchedule, [
  //   deployer,
  //   1551830400,
  //   4,
  // ]);
  // deployments["SupplySchedule"] = SupplySchedule.address;
  // await verify(contractsPath.SupplySchedule, SupplySchedule.address);

  // const TradingRewards = await contractDeploy("TradingRewards", [
  //   deployer,
  //   deployer, // periodController
  //   deployments["AddressResolver"],
  // ]);
  // deployments["TradingRewards"] = TradingRewards.address;
  // await verify("TradingRewards", TradingRewards.address);

  // const DirectIntegrationManager = await contractDeploy(
  //   "DirectIntegrationManager",
  //   [deployer, deployments["AddressResolver"]]
  // );
  // deployments["DirectIntegrationManager"] = DirectIntegrationManager.address;
  // await verify("DirectIntegrationManager", DirectIntegrationManager.address);

  // const Synthetix = await contractDeploy("Synthetix", [
  //   deployments["ProxySNX"],
  //   deployments["TokenStateSNX"],
  //   deployer,
  //   0,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["Synthetix"] = Synthetix.address;
  // await verify("Synthetix", Synthetix.address);

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

  // const FeePoolEternalStorage = await contractDeploy("FeePoolEternalStorage", [
  //   deployer,
  //   deployments["FeePool"],
  // ]);
  // deployments["FeePoolEternalStorage"] = FeePoolEternalStorage.address;
  // await verify("FeePoolEternalStorage", FeePoolEternalStorage.address);

  // const RewardEscrow = await contractDeploy(contractsPath.RewardEscrow, [
  //   deployer,
  //   deployments["Synthetix"],
  //   deployments["FeePool"],
  // ]);
  // deployments["RewardEscrow"] = RewardEscrow.address;
  // await verify(contractsPath.RewardEscrow, RewardEscrow.address);

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

  // const FuturesMarketManager = await contractDeploy("FuturesMarketManager", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["FuturesMarketManager"] = FuturesMarketManager.address;
  // await verify("FuturesMarketManager", FuturesMarketManager.address);

  // const LiquidatorRewards = await contractDeploy("LiquidatorRewards", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["LiquidatorRewards"] = LiquidatorRewards.address;
  // await verify("LiquidatorRewards", LiquidatorRewards.address);

  // const SynthetixDebtShare = await contractDeploy("SynthetixDebtShare", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynthetixDebtShare"] = SynthetixDebtShare.address;
  // await verify("SynthetixDebtShare", SynthetixDebtShare.address);

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

  // const RewardEscrowV2Storage = await contractDeploy("RewardEscrowV2Storage", [
  //   deployer,
  //   deployments["RewardEscrowV2"],
  // ]);
  // deployments["RewardEscrowV2Storage"] = RewardEscrowV2Storage.address;
  // await verify("RewardEscrowV2Storage", RewardEscrowV2Storage.address);

  // const RewardsDistribution = await contractDeploy("RewardsDistribution", [
  //   deployer,
  //   deployments["Synthetix"],
  //   deployments["ProxySNX"],
  //   deployments["RewardEscrowV2"],
  //   deployments["ProxyFeePool"],
  // ]);
  // deployments["RewardsDistribution"] = RewardsDistribution.address;
  // await verify("RewardsDistribution", RewardsDistribution.address);

  // const RewardEscrowV2Frozen = await contractDeploy("RewardEscrowV2Frozen", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["RewardEscrowV2Frozen"] = RewardEscrowV2Frozen.address;
  // await verify("RewardEscrowV2Frozen", RewardEscrowV2Frozen.address);

  // const EternalStorage = await contractDeploy("EternalStorage", [
  //   deployer,
  //   deployments["SynthsUSD"],
  // ]);
  // deployments["EternalStorage"] = EternalStorage.address;
  // await verify("EternalStorage", EternalStorage.address);

  // const DelegateApprovals = await contractDeploy("DelegateApprovals", [
  //   deployer,
  //   deployments["EternalStorage"],
  // ]);
  // deployments["DelegateApprovals"] = DelegateApprovals.address;
  // await verify("DelegateApprovals", DelegateApprovals.address);

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

  // const AggregatorETH = await contractDeploy("AggregatorETH", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["AggregatorETH"] = AggregatorETH.address;
  // await verify("AggregatorETH", AggregatorETH.address);

  // const AggregatorCollateral = await contractDeploy("AggregatorCollateral", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["AggregatorCollateral"] = AggregatorCollateral.address;
  // await verify("AggregatorCollateral", AggregatorCollateral.address);

  // const AggregatorIssuedSynths = await contractDeploy(
  //   "AggregatorIssuedSynths",
  //   [deployments["AddressResolver"]]
  // );
  // deployments["AggregatorIssuedSynths"] = AggregatorIssuedSynths.address;
  // await verify("AggregatorIssuedSynths", AggregatorIssuedSynths.address);

  // const AggregatorDebtRatio = await contractDeploy("AggregatorDebtRatio", [
  //   deployments["AddressResolver"],
  // ]);
  // deployments["AggregatorDebtRatio"] = AggregatorDebtRatio.address;
  // await verify("AggregatorDebtRatio", AggregatorDebtRatio.address);

  // // // ============================================================ //

  // // * Write deployment addresses to file
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));
  // console.log("--- DEPLOYMENTS UPDATED ---");

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

  // const tokenStateSNX = await ethers.getContractAt(
  //   contractsPath.TokenState,
  //   deployments["TokenStateSNX"],
  //   signer
  // );
  // await tokenStateSNX.setAssociatedContract(deployments["Synthetix"]);

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

  // // const FactoryContract = new ethers.Contract(
  // //   deployments["UniswapFactory"],
  // //   uniswapFactory,
  // //   signer
  // // );

  // // const cTx = await FactoryContract.createPair(
  // //   deployments["ProxySNX"],
  // //   deployments["WETH"]
  // // );
  // // await cTx.wait(6);
  // // deployments["SMXWETH"] = await FactoryContract.getPair(
  // //   deployments["ProxySNX"],
  // //   deployments["WETH"]
  // // );

  console.log("--- COMPLETED ---");
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
