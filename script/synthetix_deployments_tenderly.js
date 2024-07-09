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
  TestToken: "src/contracts/test/Token.sol:Token",
  Synthetix: "src/contracts/Synthetix.sol:Synthetix",
  Exchanger: "src/contracts/Exchanger.sol:Exchanger",
  ProxyERC20: "src/contracts/ProxyERC20.sol:ProxyERC20",
  TokenState: "src/contracts/TokenState.sol:TokenState",
  RewardEscrow: "src/contracts/RewardEscrow.sol:RewardEscrow",
  ExchangeRates: "src/contracts/ExchangeRates.sol:ExchangeRates",
  CollateralETH: "src/contracts/CollateralEth.sol:CollateralEth",
  SystemSettings: "src/contracts/SystemSettings.sol:SystemSettings",
  SynthetixState: "src/contracts/SynthetixState.sol:SynthetixState",
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

  // const ProxySCFX = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxySCFX"] = ProxySCFX.address;
  // await verify("ProxyERC20", ProxySCFX.address);
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

  // const SynthetixState = await contractDeploy("SynthetixState", [
  //   deployer,
  //   ADDRESS_ZERO, // synthetix
  // ]);
  // deployments["SynthetixState"] = SynthetixState.address;
  // await verify("SynthetixState", SynthetixState.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const TokenStateSCFX = await contractDeploy("LegacyTokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // synthetix
  // ]);
  // deployments["TokenStateSCFX"] = TokenStateSCFX.address;
  // await verify("LegacyTokenState", TokenStateSCFX.address);
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

  // const Synthetix = await contractDeploy("Synthetix", [
  //   deployments["ProxySCFX"],
  //   deployments["TokenStateSCFX"],
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
  //   deployments["ProxySCFX"],
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

  // const Staking = await contractDeploy("Staking", [
  //   deployments["ProxySCFX"],
  //   deployments["ProxySCFX"],
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
  //   deployments["ProxySCFX"],
  //   deployments["WETH"]
  // );
  // deployments["SCFXWETH"] = await FactoryContract.getPair(
  //   deployments["ProxySCFX"],
  //   deployments["WETH"]
  // );
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // await FactoryContract.createPair(
  //   deployments["TestToken"],
  //   deployments["ProxysUSD"]
  // );
  // deployments["TKNUSD"] = await FactoryContract.getPair(
  //   deployments["TestToken"],
  //   deployments["ProxysUSD"]
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
  // names.push(ethers.utils.formatBytes32String("ProxySCFX"));
  // addresses.push(deployments["ProxySCFX"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("SystemStatus"));
  // addresses.push(deployments["SystemStatus"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("TokenStateSCFX"));
  // addresses.push(deployments["TokenStateSCFX"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("TokenStatesUSD"));
  // addresses.push(deployments["TokenStatesUSD"]);
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
  // names.push(ethers.utils.formatBytes32String("SynthetixBridgeToOptimism"));
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

  // const proxySCFX = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxySCFX"],
  //   signer
  // );
  // await proxySCFX.updateTarget(deployments["Synthetix"]);

  // const proxysUSD = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxysUSD"],
  //   signer
  // );
  // await proxysUSD.updateTarget(deployments["SynthsUSD"]);

  // const proxysETH = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxysETH"],
  //   signer
  // );
  // await proxysETH.updateTarget(deployments["SynthsETH"]);

  // const proxyFeePool = await ethers.getContractAt(
  //   contractsPath.Proxy,
  //   deployments["ProxyFeePool"],
  //   signer
  // );
  // await proxyFeePool.updateTarget(deployments["FeePool"]);

  // const synthetixState = await ethers.getContractAt(
  //   contractsPath.SynthetixState,
  //   deployments["SynthetixState"],
  //   signer
  // );
  // await synthetixState.linkContract(deployments["Synthetix"]);

  // const tokenStateSCFX = await ethers.getContractAt(
  //   contractsPath.TokenState,
  //   deployments["TokenStateSCFX"],
  //   signer
  // );
  // await tokenStateSCFX.linkContract(deployments["Synthetix"]);

  // const tokenStatesUSD = await ethers.getContractAt(
  //   contractsPath.TokenState,
  //   deployments["TokenStatesUSD"],
  //   signer
  // );
  // await tokenStatesUSD.linkContract(deployments["SynthsUSD"]);

  // const tokenStatesETH = await ethers.getContractAt(
  //   contractsPath.TokenState,
  //   deployments["TokenStatesETH"],
  //   signer
  // );
  // await tokenStatesETH.linkContract(deployments["SynthsETH"]);

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
  //   ethers.utils.formatBytes32String("SCFX"),
  //   deployments["AggregatorCollateral"] // aggregatorSynth
  // );
  // await exchangeRates.addAggregator(
  //   ethers.utils.formatBytes32String("sETH"),
  //   deployments["AggregatorETH"] // aggregatorSynth
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
  // synthKeys.push(ethers.utils.formatBytes32String("sUSD"));
  // synthKeys.push(ethers.utils.formatBytes32String("sETH"));
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

  // const synthetix = await ethers.getContractAt(
  //   contractsPath.Synthetix,
  //   deployments["Synthetix"],
  //   signer
  // );
  // const proxySCFX = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxySCFX"],
  //   signer
  // );

  // await synthetix.mint(deployer, parseEth(1000000));
  // await synthetix.setReserveAddress(reserveAddr);
  // await synthetix.setPool(deployments["SCFXWETH"], true);
  // await synthetix.setTrade(true);

  // await proxySCFX.transfer(user1, parseEth(1000));
  // await proxySCFX.transfer(user2, parseEth(1000));
  // await proxySCFX.transfer(reserveAddr, parseEth(200000));

  // // await synthetix.createMaxSynths();
  // // await synthetix.executeExchange(
  // //   ethers.utils.formatBytes32String("sUSD"),
  // //   parseEth(50),
  // //   ethers.utils.formatBytes32String("sETH")
  // // );

  // const RouterContract = new ethers.Contract(
  //   deployments["UniswapRouter"],
  //   uniswapRouter,
  //   signer
  // );
  // const proxysUSD = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxysUSD"],
  //   signer
  // );
  // const testToken = await ethers.getContractAt(
  //   contractsPath.TestToken,
  //   deployments["TestToken"],
  //   signer
  // );

  // await proxysUSD.approve(deployments["UniswapRouter"], parseEth(100));
  // await testToken.approve(deployments["UniswapRouter"], parseEth(100));
  // await RouterContract.addLiquidity(
  //   deployments["ProxysUSD"],
  //   deployments["TestToken"],
  //   parseEth(100),
  //   parseEth(100),
  //   1,
  //   1,
  //   deployer,
  //   Math.round(Date.now() / 1000) + 1000
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
  //   2344 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyWheat",
  //   "SynthWheat",
  //   "Wheat",
  //   "TokenStateWheat",
  //   "AggregatorWheat",
  //   729 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyCrudeOil",
  //   "SynthCrudeOil",
  //   "CrudeOil",
  //   "TokenStateCrudeOil",
  //   "AggregatorCrudeOil",
  //   79 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyOrangeJuice",
  //   "SynthOrangeJuice",
  //   "OrangeJuice",
  //   "TokenStateOrangeJuice",
  //   "AggregatorOrangeJuice",
  //   477 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxySilver",
  //   "SynthSilver",
  //   "Silver",
  //   "TokenStateSilver",
  //   "AggregatorSilver",
  //   32 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyPlatinum",
  //   "SynthPlatinum",
  //   "Platinum",
  //   "TokenStatePlatinum",
  //   "AggregatorPlatinum",
  //   1046 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyPalladium",
  //   "SynthPalladium",
  //   "Palladium",
  //   "TokenStatePalladium",
  //   "AggregatorPalladium",
  //   957 * 10 ** 8
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
  //   233 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxySugar",
  //   "SynthSugar",
  //   "Sugar",
  //   "TokenStateSugar",
  //   "AggregatorSugar",
  //   18 * 10 ** 8
  // );
  // await deploySynth(
  //   "ProxyCotton",
  //   "SynthCotton",
  //   "Cotton",
  //   "TokenStateCotton",
  //   "AggregatorCotton",
  //   81 * 10 ** 8
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
  //   2.456 * 10 ** 8
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
  //   9423 * 10 ** 8
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
