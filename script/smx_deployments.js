const { tenderly } = require("hardhat");

const { readFileSync, writeFileSync } = require("fs");
const outputFilePath = "./smx_test_tenderly_deployments.json";
// const outputFilePath = "./smx_tenderly_deployments.json";

const WETH = require("../abis/weth.json");
const uniswapRouter = require("../abis/uniswap-router.json");
const uniswapFactory = require("../abis/uniswap-factory.json");

const { resolve } = require("path");
const { config } = require("dotenv");

config({ path: resolve(__dirname, "./.env") });

const parseEth = (eth) => ethers.utils.parseEther(String(eth));
const parseUnits = (eth) => ethers.utils.parseUnits(String(eth), 6);

const contractsPath = {
  SMX: "src/contracts/SMX/SMX.sol:SMX",
  Staking: "src/contracts/staking/Staking.sol:Staking",
  // SupplySchedule: "src/contracts/SupplySchedule.sol:SupplySchedule",
};

async function main() {
  const deployments = JSON.parse(readFileSync(outputFilePath, "utf-8"));

  // * Second parameter is chainId, 1 for Ethereum mainnet
  const provider_tenderly = new ethers.providers.JsonRpcProvider(
    `${process.env.TENDERLY_MAINNET_FORK_URL_TEST}`,
    // `${process.env.TENDERLY_MAINNET_FORK_URL}`,
    1
  );
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider_tenderly);

  const deployer = "0xE536B4D7cf1e346D985cEe807e16B1b11B019976";
  const user = "0xc5Fa3B9D1C223E96eC77CB48880eeBeb9DaB4ad7";
  const treasury = "0x35D9466FFa2497fa919203809C2F150F493A0f73";

  // ! ------------------------------------------------------------------------
  // ! DEPLOYMENTS ------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  // // const PriceOracle = await contractDeploy("PriceOracle", [parseEth(1)]);
  // // deployments["PriceOracle"] = PriceOracle.address;
  // // await verify("PriceOracle", PriceOracle.address);

  // const SMX = await contractDeploy("SMX", [
  //   "SMX",
  //   "SMX",
  //   deployer,
  //   parseEth(100_000_000),
  // ]);
  // deployments["SMX"] = SMX.address;
  // await verify("SMX", SMX.address);

  // const Staking = await contractDeploy("Staking", [
  //   deployments["SMX"],
  //   deployments["SMX"],
  // ]);
  // deployments["Staking"] = Staking.address;
  // await verify("Staking", Staking.address);

  // const FactoryContract = new ethers.Contract(
  //   deployments["UniswapFactory"],
  //   uniswapFactory,
  //   signer
  // );
  // await FactoryContract.createPair(deployments["SMX"], deployments["WETH"]);
  // deployments["SMXWETH"] = await FactoryContract.getPair(
  //   deployments["SMX"],
  //   deployments["WETH"]
  // );

  const SynthSwap = await contractDeploy("SynthSwap", [
    deployments["SMX"],
    deployments["SMX"],
  ]);
  deployments["SynthSwap"] = SynthSwap.address;
  await verify("SynthSwap", SynthSwap.address);

  // //   const SupplySchedule = await contractDeploy("SupplySchedule", [
  // //     deployer,
  // //     1551830400,
  // //     4,
  // //   ]);
  // //   deployments["SupplySchedule"] = SupplySchedule.address;
  // //   await verify("SupplySchedule", SupplySchedule.address);

  // // ============================================================ //

  // * Write deployment addresses to file
  writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));
  console.log("Completed");

  // // ============================================================ //

  // ! ------------------------------------------------------------------------
  // ! SETUP ------------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  const smx = await ethers.getContractAt(
    contractsPath.SMX,
    deployments["SMX"],
    signer
  );
  await smx.transfer(deployments["Staking"], parseEth(100));
  await smx.setExcludeFromFee(deployments["SMX"], true);
  await smx.setRouter(deployments["UniswapRouter"]);
  await smx.setRewardAddress(deployments["WETH"]);
  await smx.setPool(deployments["SMXWETH"], true);
  await smx.setFeeTaker(treasury, 50);
  await smx.setFeeTaker(user, 50);
  await smx.setDeploy(true);
  await smx.setTrade(true);

  const WETHContract = new ethers.Contract(deployments["WETH"], WETH, signer);
  const RouterContract = new ethers.Contract(
    deployments["UniswapRouter"],
    uniswapRouter,
    signer
  );
  await smx.approve(deployments["UniswapRouter"], parseEth(1000));
  await WETHContract.approve(deployments["UniswapRouter"], parseEth(1000));
  await RouterContract.addLiquidity(
    deployments["SMX"],
    deployments["WETH"],
    parseEth(1000),
    parseEth(1000),
    1,
    1,
    deployer,
    Math.round(Date.now() / 1000) + 1000
  );
  console.log("ADDED LIQUIDITY");

  // // const supplySchedule = await ethers.getContractAt(
  // //   contractsPath.SupplySchedule,
  // //   deployments["SupplySchedule"],
  // //   signer
  // // );
  // // await supplySchedule.setSynthetixProxy(deployments["SMX"]);
  // // await supplySchedule.setInflationAmount(3000000 * 10 ** 18);
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
