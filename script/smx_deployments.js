const { tenderly } = require("hardhat");

const { readFileSync, writeFileSync } = require("fs");
const outputFilePath = "./smx_tenderly_deployments.json";

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

  const PriceOracle = await contractDeploy("PriceOracle", [parseEth(1)]);
  deployments["PriceOracle"] = PriceOracle.address;
  await verify("PriceOracle", PriceOracle.address);

  const SMX = await contractDeploy("SMX", [
    "SMX",
    "SMX",
    deployer,
    parseEth(100_000_000),
  ]);
  deployments["SMX"] = SMX.address;
  await verify("SMX", SMX.address);

  const Staking = await contractDeploy("Staking", [
    deployments["SMX"],
    deployments["SMX"],
  ]);
  deployments["Staking"] = Staking.address;
  await verify("Staking", Staking.address);

  //   const SupplySchedule = await contractDeploy("SupplySchedule", [
  //     deployer,
  //     1551830400,
  //     4,
  //   ]);
  //   deployments["SupplySchedule"] = SupplySchedule.address;
  //   await verify("SupplySchedule", SupplySchedule.address);

  // ! ------------------------------------------------------------------------
  // ! SETUP ------------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  const FactoryContract = new ethers.Contract(
    deployments["UniswapFactory"],
    uniswapFactory,
    signer
  );

  const cTx = await FactoryContract.createPair(
    deployments["SMX"],
    deployments["WETH"]
  );
  // await cTx.wait(6);
  deployments["SMXWETH"] = await FactoryContract.getPair(
    deployments["SMX"],
    deployments["WETH"]
  );

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

  // const supplySchedule = await ethers.getContractAt(
  //   contractsPath.SupplySchedule,
  //   deployments["SupplySchedule"],
  //   signer
  // );
  // await supplySchedule.setSynthetixProxy(deployments["SMX"]);
  // await supplySchedule.setInflationAmount(3000000 * 10 ** 18);

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
