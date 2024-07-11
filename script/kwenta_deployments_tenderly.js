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

  const deployer = "0x0f6A0fBb5a9E10f50f364b2409a5Bbb9aFa52059";
  const treasury = "0xa6C40e6Ea900EF92FD8459c86FA290a282b0aCE5";

  // ! ------------------------------------------------------------------------
  // ! DEPLOYMENTS ------------------------------------------------------------
  // ! ------------------------------------------------------------------------

  // const SynthSwap = await contractDeploy("SynthSwap", [
  //   deployments["ProxycfUSD"],
  //   deployments["UniswapSwapRouter"],
  //   deployments["AddressResolver"],
  //   deployer,
  //   treasury,
  // ]);
  // deployments["SynthSwap"] = SynthSwap.address;
  // await verify("SynthSwap", SynthSwap.address);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));

  // // ============================================================ //

  // * Write deployment addresses to file
  console.log("--- DEPLOYMENTS UPDATED ---");

  // // ============================================================ //

  // ! ------------------------------------------------------------------------
  // ! SETUP ------------------------------------------------------------------
  // ! ------------------------------------------------------------------------

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
