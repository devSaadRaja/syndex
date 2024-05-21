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
const uniswapRouter = require("../abis/uniswap-router.json");
const uniswapFactory = require("../abis/uniswap-factory.json");

const { resolve } = require("path");
const { config } = require("dotenv");

config({ path: resolve(__dirname, "./.env") });

const parseEth = (eth) => ethers.utils.parseEther(String(eth));

const contractsPath = {
  SMX: "src/contracts/SMX/SMX.sol:SMX",
  Staking: "src/contracts/staking/Staking.sol:Staking",
  SMXRewardEscrow: "src/contracts/SMX/RewardEscrow.sol:RewardEscrow",
  SMXSupplySchedule: "src/contracts/SMX/SupplySchedule.sol:SupplySchedule",
};

async function main() {
  const deployments = JSON.parse(readFileSync(outputFilePath, "utf-8"));

  const provider_tenderly = new ethers.providers.JsonRpcProvider(url, chainId);
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
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const Staking = await contractDeploy("Staking", [
  //   deployments["SMX"],
  //   deployments["SMX"],
  // ]);
  // deployments["Staking"] = Staking.address;
  // await verify("Staking", Staking.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

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
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SMXRewardEscrow = await contractDeploy(contractsPath.SMXRewardEscrow, [
  //   deployer,
  //   deployments["SMX"],
  // ]);
  // deployments["SMXRewardEscrow"] = SMXRewardEscrow.address;
  // await verify(contractsPath.SMXRewardEscrow, SMXRewardEscrow.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const MultipleMerkleDistributor = await contractDeploy(
  //   "MultipleMerkleDistributor",
  //   [deployer, deployments["SMX"], deployments["SMXRewardEscrow"]]
  // );
  // deployments["MultipleMerkleDistributor"] = MultipleMerkleDistributor.address;
  // await verify("MultipleMerkleDistributor", MultipleMerkleDistributor.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SMXSupplySchedule = await contractDeploy(
  //   contractsPath.SMXSupplySchedule,
  //   [deployer, treasury],
  //   {
  //     libraries: {
  //       SafeDecimalMath: deployments["SafeDecimalMath"],
  //     },
  //   }
  // );
  // deployments["SMXSupplySchedule"] = SMXSupplySchedule.address;
  // await verify(contractsPath.SMXSupplySchedule, SMXSupplySchedule.address, {
  //   SafeDecimalMath: deployments["SafeDecimalMath"],
  // });
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const SynthSwap = await contractDeploy("SynthSwap", [
  //   deployments["ProxysUSD"],
  //   deployments["UniswapSwapRouter"],
  //   deployments["AddressResolver"],
  //   deployer,
  //   treasury,
  // ]);
  // deployments["SynthSwap"] = SynthSwap.address;
  // await verify("SynthSwap", SynthSwap.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // const DappMaintenance = await contractDeploy("DappMaintenance", [deployer]);
  // deployments["DappMaintenance"] = DappMaintenance.address;
  // await verify("DappMaintenance", DappMaintenance.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // // vSmxRedeemer = new vSMXRedeemer(address(smx), address(smx));

  // // ============================================================ //

  // * Write deployment addresses to file
  console.log("--- DEPLOYMENTS UPDATED ---");

  // // ============================================================ //

  // ! ------------------------------------------------------------------------
  // ! SETUP ------------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  // const smx = await ethers.getContractAt(
  //   contractsPath.SMX,
  //   deployments["SMX"],
  //   signer
  // );
  // await smx.transfer(deployments["Staking"], parseEth(100));
  // await smx.setExcludeFromFee(deployments["SMX"], true);
  // await smx.setRouter(deployments["UniswapRouter"]);
  // await smx.setRewardAddress(deployments["WETH"]);
  // await smx.setPool(deployments["SMXWETH"], true);
  // await smx.setFeeTaker(treasury, 50);
  // await smx.setFeeTaker(user, 50);
  // await smx.setDeploy(true);
  // await smx.setTrade(true);

  // const WETHContract = new ethers.Contract(deployments["WETH"], WETH, signer);
  // const RouterContract = new ethers.Contract(
  //   deployments["UniswapRouter"],
  //   uniswapRouter,
  //   signer
  // );
  // await smx.approve(deployments["UniswapRouter"], parseEth(1000));
  // await WETHContract.approve(deployments["UniswapRouter"], parseEth(1000));
  // await RouterContract.addLiquidity(
  //   deployments["SMX"],
  //   deployments["WETH"],
  //   parseEth(1000),
  //   parseEth(1000),
  //   1,
  //   1,
  //   deployer,
  //   Math.round(Date.now() / 1000) + 1000
  // );
  // console.log("ADDED LIQUIDITY");

  // const supplySchedule = await ethers.getContractAt(
  //   contractsPath.SMXSupplySchedule,
  //   deployments["SMXSupplySchedule"],
  //   signer
  // );
  // await supplySchedule.setSMX(deployments["SMX"]);
  // await supplySchedule.setStakingRewards(deployments["Staking"]);
  // await supplySchedule.setTradingRewards(
  //   deployments["MultipleMerkleDistributor"]
  // );

  // // multipleMerkleDistributor.setMerkleRootForEpoch();

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
