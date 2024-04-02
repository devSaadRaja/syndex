const { tenderly } = require("hardhat");

const { readFileSync, writeFileSync } = require("fs");
const outputFilePath = "./tenderly_deployments.json";

const uniswapRouter = require("../abis/uniswap-router.json");
const uniswapFactory = require("../abis/uniswap-factory.json");

const { resolve } = require("path");
const { config } = require("dotenv");

config({ path: resolve(__dirname, "./.env") });

const parseEth = (eth) => ethers.utils.parseEther(String(eth));
const parseUnits = (eth) => ethers.utils.parseUnits(String(eth), 6);
const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

const contractsPath = {
  SupplySchedule: "src/contracts/SupplySchedule.sol:SupplySchedule",
  ExchangeRates: "src/contracts/ExchangeRates.sol:ExchangeRates",
  ProxyERC20: "src/contracts/ProxyERC20.sol:ProxyERC20",
  TokenState: "src/contracts/TokenState.sol:TokenState",
  Synthetix: "src/contracts/Synthetix.sol:Synthetix",
  Taxable: "src/contracts/tax/Taxable.sol:Taxable",
  Staking: "src/contracts/staking/Staking.sol:Staking",
};

async function main() {
  const deployments = JSON.parse(readFileSync(outputFilePath, "utf-8"));

  // * Second parameter is chainId, 1 for Ethereum mainnet
  const provider_tenderly = new ethers.providers.JsonRpcProvider(
    `${process.env.TENDERLY_MAINNET_FORK_URL}`,
    1
  );
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider_tenderly);

  const deployer = "0xE536B4D7cf1e346D985cEe807e16B1b11B019976";
  const user = "0xc5Fa3B9D1C223E96eC77CB48880eeBeb9DaB4ad7";
  const treasury = "0x35D9466FFa2497fa919203809C2F150F493A0f73";

  // ! ------------------------------------------------------------------------
  // ! DEPLOYMENTS ------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  const SafeDecimalMath = await contractDeploy("SafeDecimalMath", []);
  deployments["SafeDecimalMath"] = SafeDecimalMath.address;
  await verify("SafeDecimalMath", SafeDecimalMath.address);

  const SystemStatus = await contractDeploy("SystemStatus", [deployer]);
  deployments["SystemStatus"] = SystemStatus.address;
  await verify("SystemStatus", SystemStatus.address);

  const AddressResolver = await contractDeploy("AddressResolver", [deployer]);
  deployments["AddressResolver"] = AddressResolver.address;
  await verify("AddressResolver", AddressResolver.address);

  const Issuer = await contractDeploy(
    "Issuer",
    [deployer, deployments["AddressResolver"]],
    { SafeDecimalMath: deployments["SafeDecimalMath"] }
  );
  deployments["Issuer"] = Issuer.address;
  await verify("Issuer", Issuer.address);

  const AggregatorCollateral = await contractDeploy("AggregatorCollateral", [
    deployments["AddressResolver"],
  ]);
  deployments["AggregatorCollateral"] = AggregatorCollateral.address;
  await verify("AggregatorCollateral", AggregatorCollateral.address);

  const ExchangeRates = await contractDeploy("ExchangeRates", [
    deployer,
    deployments["AddressResolver"],
  ]);
  deployments["ExchangeRates"] = ExchangeRates.address;
  await verify("ExchangeRates", ExchangeRates.address);

  const ProxySNX = await contractDeploy("ProxyERC20", [deployer]);
  deployments["ProxySNX"] = ProxySNX.address;
  await verify("ProxyERC20", ProxySNX.address);

  const TokenState = await contractDeploy("TokenState", [
    deployer,
    ADDRESS_ZERO, // Synthetix.address,
  ]);
  deployments["TokenState"] = TokenState.address;
  await verify("TokenState", TokenState.address);

  const Synthetix = await contractDeploy("Synthetix", [
    deployments["ProxySNX"],
    deployments["TokenState"],
    deployer,
    parseEth(100_000_000),
    deployments["AddressResolver"],
  ]);
  deployments["Synthetix"] = Synthetix.address;
  await verify("Synthetix", Synthetix.address);

  const Staking = await contractDeploy("Staking", [
    deployments["ProxySNX"],
    deployments["ProxySNX"],
  ]);
  deployments["Staking"] = Staking.address;
  await verify("Staking", Staking.address);

  const Taxable = await contractDeploy("Taxable", [
    deployments["ProxySNX"],
    deployments["Synthetix"],
    deployments["WETH"],
    deployments["UniswapRouter"],
  ]);
  deployments["Taxable"] = Taxable.address;
  await verify("Taxable", Taxable.address);

  const SupplySchedule = await contractDeploy("SupplySchedule", [
    deployer,
    1551830400,
    4,
  ]);
  deployments["SupplySchedule"] = SupplySchedule.address;
  await verify("SupplySchedule", SupplySchedule.address);

  // ! ------------------------------------------------------------------------
  // ! SETUP ------------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  // const issuer = await ethers.getContractAt(
  //   contractsPath.Issuer,
  //   deployments["Issuer"],
  //   signer
  // );
  // issuer.addSynth(SynthsUSD.address);
  // issuer.addSynth(SynthsETH.address);

  const exchangeRates = await ethers.getContractAt(
    contractsPath.ExchangeRates,
    deployments["ExchangeRates"],
    signer
  );
  await exchangeRates.addAggregator(
    ethers.utils.formatBytes32String("SNX"),
    deployments["AggregatorCollateral"]
  );

  const proxySNX = await ethers.getContractAt(
    contractsPath.ProxyERC20,
    deployments["ProxySNX"],
    signer
  );
  await proxySNX.setTarget(deployments["Synthetix"]);

  const tokenState = await ethers.getContractAt(
    contractsPath.TokenState,
    deployments["TokenState"],
    signer
  );
  await tokenState.setAssociatedContract(deployments["Synthetix"]);

  const FactoryContract = new ethers.Contract(
    deployments["UniswapFactory"],
    uniswapFactory,
    signer
  );

  const cTx = await FactoryContract.createPair(
    deployments["Taxable"],
    deployments["WETH"]
  );
  await cTx.wait(6);
  deployments["SMXWETH"] = await FactoryContract.getPair(
    deployments["ProxySNX"],
    deployments["WETH"]
  );

  const taxable = await ethers.getContractAt(
    contractsPath.Taxable,
    deployments["Taxable"],
    signer
  );
  await taxable.setFeeTaker(user, 50);
  await taxable.setFeeTaker(treasury, 50);
  await taxable.setPool(deployments["SMXPAIR"], true);
  await taxable.setExcludeFromFee(deployments["Taxable"], true);

  const synthetix = await ethers.getContractAt(
    contractsPath.Synthetix,
    deployments["Synthetix"],
    signer
  );
  await synthetix.setTrade(true);
  await synthetix.setDeploy(true);
  await synthetix.setTaxable(deployments["Taxable"]);

  const supplySchedule = await ethers.getContractAt(
    contractsPath.SupplySchedule,
    deployments["SupplySchedule"],
    signer
  );
  await supplySchedule.setSynthetixProxy(deployments["ProxySNX"]);
  await supplySchedule.setInflationAmount(3000000 * 10 ** 18);

  // const RouterContract = new ethers.Contract(
  //   deployments["UniswapRouter"],
  //   uniswapRouter,
  //   signer
  // );
  // await proxySNX.approve(deployments["UniswapRouter"], parseUnits(1800));
  // await WETH.approve(deployments["UniswapRouter"], parseEth(81000000));
  // delay(30000);
  // console.log("APPROVED TOKENS TO ROUTER");
  // await RouterContract.addLiquidity(
  //   deployments["ProxySNX"],
  //   deployments["WETH"],
  //   parseEth(81000000),
  //   parseEth(1800),
  //   1,
  //   1,
  //   deployer,
  //   Math.round(Date.now() / 1000) + 1000
  // );
  // console.log("ADDED LIQUIDITY");

  // // ============================================================ //

  // * Write deployment addresses to file
  writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));
  console.log("Completed");
}

const contractDeploy = async (name, args) => {
  const contractFactory = await ethers.getContractFactory(name);
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
