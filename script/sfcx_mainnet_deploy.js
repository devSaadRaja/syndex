const { readFileSync, writeFileSync } = require("fs");

const WETH = require("../abis/weth.json");
const uniswapRouter = require("../abis/uniswap-router.json");
const uniswapFactory = require("../abis/uniswap-factory.json");

const { resolve } = require("path");
const { config } = require("dotenv");

config({ path: resolve(__dirname, "./.env") });

var outputFilePath = "./deployments_testnet.json";

const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

const parseEth = (eth) => ethers.utils.parseEther(String(eth));
const formatEth = (wei) => Number(ethers.utils.formatEther(String(wei)));

const contractsPath = {
  LegacyTokenState: "src/contracts/LegacyTokenState.sol:LegacyTokenState",
  AddressResolver: "src/contracts/AddressResolver.sol:AddressResolver",
  ProxyERC20: "src/contracts/ProxyERC20.sol:ProxyERC20",
  SynDex: "src/contracts/SynDex.sol:SynDex",
};

const deployments = JSON.parse(readFileSync(outputFilePath, "utf-8"));

const provider = new ethers.providers.JsonRpcProvider(
  `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
  11155111 // 1
);

const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const signer1 = new ethers.Wallet(process.env.PRIVATE_KEY_1, provider);
const signer2 = new ethers.Wallet(process.env.PRIVATE_KEY_2, provider);
const signer3 = new ethers.Wallet(process.env.PRIVATE_KEY_3, provider);

const deployer = "0x0f6A0fBb5a9E10f50f364b2409a5Bbb9aFa52059";
const user1 = "0x3555f3e074467D24820f14db7e064302e386a57D";
const user2 = "0xcE4a1e96EB50E62d4920cb6424358404AA5570Be";
const treasury = "0xa6C40e6Ea900EF92FD8459c86FA290a282b0aCE5";
const reserveAddr = "0xEA1b7aF13E723D4598aA384e0b5b80FCB4147F48";

async function main() {
  // ! ------------------------------------------------------------------------
  // ! DEPLOYMENTS ------------------------------------------------------------
  // ! ------------------------------------------------------------------------
  // const AddressResolver = await contractDeploy("AddressResolver", [deployer]);
  // deployments["AddressResolver"] = AddressResolver.address;
  // await AddressResolver.deployTransaction.wait(5);
  // await verify(AddressResolver.address, [deployer]);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));
  // const ProxySFCX = await contractDeploy("ProxyERC20", [deployer]);
  // deployments["ProxySFCX"] = ProxySFCX.address;
  // await ProxySFCX.deployTransaction.wait(5);
  // await verify(ProxySFCX.address, [deployer]);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));
  // const SystemStatus = await contractDeploy("SystemStatus", [deployer]);
  // deployments["SystemStatus"] = SystemStatus.address;
  // await SystemStatus.deployTransaction.wait(5);
  // await verify(SystemStatus.address, [deployer]);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));
  // const Issuer = await contractDeploy("Issuer", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["Issuer"] = Issuer.address;
  // await Issuer.deployTransaction.wait(5);
  // await verify(Issuer.address, [deployer, deployments["AddressResolver"]]);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));
  // const TokenStateSFCX = await contractDeploy("LegacyTokenState", [
  //   deployer,
  //   ADDRESS_ZERO, // syndex
  // ]);
  // deployments["TokenStateSFCX"] = TokenStateSFCX.address;
  // await TokenStateSFCX.deployTransaction.wait(5);
  // await verify(TokenStateSFCX.address, [
  //   deployer,
  //   ADDRESS_ZERO, // syndex
  // ]);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));
  // const SynDexDebtShare = await contractDeploy("SynDexDebtShare", [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynDexDebtShare"] = SynDexDebtShare.address;
  // await SynDexDebtShare.deployTransaction.wait(5);
  // await verify(SynDexDebtShare.address, [
  //   deployer,
  //   deployments["AddressResolver"],
  // ]);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));
  // const SynDex = await contractDeploy("SynDex", [
  //   deployments["ProxySFCX"],
  //   deployments["TokenStateSFCX"],
  //   deployer,
  //   0,
  //   deployments["AddressResolver"],
  // ]);
  // deployments["SynDex"] = SynDex.address;
  // await SynDex.deployTransaction.wait(5);
  // await verify(SynDex.address, [
  //   deployments["ProxySFCX"],
  //   deployments["TokenStateSFCX"],
  //   deployer,
  //   0,
  //   deployments["AddressResolver"],
  // ]);
  // writeFileSync(outputFilePath, JSON.stringify(deployments, null, 2));
  // // * PAIR vvv
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
  // // ============================================================ //
  // console.log("--- DEPLOYMENTS UPDATED ---");
  // // ============================================================ //
  // ! ------------------------------------------------------------------------
  // ! RESOLVER ADDRESSES -----------------------------------------------------
  // ! ------------------------------------------------------------------------
  // let count = 0;
  // let names = [];
  // let addresses = [];
  // names.push(ethers.utils.formatBytes32String("SystemStatus"));
  // addresses.push(deployments["SystemStatus"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("RewardsDistribution"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("RewardEscrow"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("FlexibleStorage"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("DelegateApprovals"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("ext:AggregatorIssuedSynths"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("ext:AggregatorDebtRatio"));
  // addresses.push(deployer);
  // count++;
  // // ! --- refreshCache vvv
  // names.push(ethers.utils.formatBytes32String("SynDexDebtShare"));
  // addresses.push(deployments["SynDexDebtShare"]);
  // count++;
  // names.push(ethers.utils.formatBytes32String("Exchanger"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("LiquidatorRewards"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("Liquidator"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("RewardEscrowV2"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("ExchangeRates"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("CircuitBreaker"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("FeePool"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("DebtCache"));
  // addresses.push(deployer);
  // count++;
  // names.push(ethers.utils.formatBytes32String("SynthRedeemer"));
  // addresses.push(deployer);
  // count++;
  // // ! ---
  // names.push(ethers.utils.formatBytes32String("SynDex"));
  // addresses.push(deployments["SynDex"]);
  // names.push(ethers.utils.formatBytes32String("Issuer"));
  // addresses.push(deployments["Issuer"]);
  // const addressResolver = await ethers.getContractAt(
  //   contractsPath.AddressResolver,
  //   deployments["AddressResolver"],
  //   signer
  // );
  // await addressResolver.loadAddresses(names, addresses);
  // const abi = ["function refreshCache() public"];
  // for (let i = count; i < addresses.length; i++) {
  //   const contract = new ethers.Contract(addresses[i], abi, signer);
  //   await contract.refreshCache();
  // }
  // ! ------------------------------------------------------------------------
  // ! SETUP ------------------------------------------------------------------
  // ! ------------------------------------------------------------------------
  // const proxySFCX = await ethers.getContractAt(
  //   contractsPath.ProxyERC20,
  //   deployments["ProxySFCX"],
  //   signer
  // );
  // const tokenStateSFCX = await ethers.getContractAt(
  //   contractsPath.LegacyTokenState,
  //   deployments["TokenStateSFCX"],
  //   signer
  // );
  // const syndex = await ethers.getContractAt(
  //   contractsPath.SynDex,
  //   deployments["SynDex"],
  //   signer
  // );
  // await proxySFCX.updateTarget(deployments["SynDex"]);
  // await tokenStateSFCX.linkContract(deployments["SynDex"]);
  // await syndex.mint(deployer, parseEth(1000000));
  // await syndex.setReserveAddress(reserveAddr);
  // await syndex.setPool(deployments["SFCXWETH"], true);
  // await syndex.setTrade(true);
  // // await proxySFCX.transfer(user1, parseEth(1000)); // !
  // // await proxySFCX.transfer(user2, parseEth(1000)); // !
  // // await proxySFCX.transfer(reserveAddr, parseEth(200000)); // !
  // // * ADD LIQUIDITY vvv
  // const weth = new ethers.Contract(deployments["WETH"], WETH, signer);
  // const RouterContract = new ethers.Contract(
  //   deployments["UniswapRouter"],
  //   uniswapRouter,
  //   signer
  // );
  // await weth.approve(deployments["UniswapRouter"], parseEth(50));
  // await proxySFCX.approve(deployments["UniswapRouter"], parseEth(50));
  // await RouterContract.addLiquidity(
  //   deployments["WETH"],
  //   deployments["ProxySFCX"],
  //   parseEth(50),
  //   parseEth(50),
  //   1,
  //   1,
  //   deployer,
  //   Math.round(Date.now() / 1000) + 1000
  // );
  // console.log("ADDED LIQUIDITY");
  // console.log("[[[ COMPLETED ]]]");
  // ! ----------------------------------
  // await testCases();
  // ! ----------------------------------
}

const testCases = async () => {
  const proxySFCX = await ethers.getContractAt(
    contractsPath.ProxyERC20,
    deployments["ProxySFCX"],
    signer
  );
  await proxySFCX.approve(reserveAddr, parseEth(1000));

  const proxySFCXReserve = await ethers.getContractAt(
    contractsPath.ProxyERC20,
    deployments["ProxySFCX"],
    signer3
  );
  await proxySFCXReserve.transferFrom(deployer, user2, parseEth(10));

  console.log(
    formatEth(await proxySFCX.balanceOf(deployer)),
    "<<< balanceOf(deployer)"
  );
  console.log(
    formatEth(await proxySFCX.balanceOf(user2)),
    "<<< balanceOf(user2)"
  );

  console.log(formatEth(await proxySFCX.totalSupply()), "<<< totalSupply");

  // ! SWAP ---

  const weth = new ethers.Contract(deployments["WETH"], WETH, signer);

  console.log();
  console.log("BEFORE SWAP");
  console.log(
    formatEth(await weth.balanceOf(user1)),
    "<<< WETH balanceOf user1"
  );
  console.log(
    formatEth(await proxySFCX.balanceOf(user1)),
    "<<< SFCX balanceOf user1"
  );

  await swap(
    signer1,
    deployments["WETH"],
    deployments["ProxySFCX"],
    parseEth(10),
    user1
  ); // * BUY
  await swap(
    signer1,
    deployments["ProxySFCX"],
    deployments["WETH"],
    parseEth(8),
    user1
  ); // * SELL

  console.log();
  console.log("AFTER SWAP");
  console.log(
    formatEth(await weth.balanceOf(user1)),
    "<<< WETH balanceOf user1"
  );
  console.log(
    formatEth(await proxySFCX.balanceOf(user1)),
    "<<< SFCX balanceOf user1"
  );
};

const swap = async (signerTx, tokenIn, tokenOut, amountIn, to) => {
  const proxySFCX = await ethers.getContractAt(
    contractsPath.ProxyERC20,
    tokenIn,
    signerTx
  );
  await proxySFCX.approve(deployments["UniswapRouter"], amountIn);

  const RouterContract = new ethers.Contract(
    deployments["UniswapRouter"],
    uniswapRouter,
    signerTx
  );

  const path = [tokenIn, tokenOut];
  await RouterContract.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    amountIn,
    0,
    path,
    to,
    Math.round(Date.now() / 1000) + 1000
  );
};

const contractDeploy = async (name, args) => {
  const contractFactory = await ethers.getContractFactory(name);
  const contract = await contractFactory.deploy(...args);
  await contract.deployTransaction.wait();

  console.info(`Deploying ${name} : ${contract.address}`);

  return contract;
};

const verify = async (address, constructorArguments) => {
  console.log("Verifying contract...");
  try {
    await run("verify:verify", { address, constructorArguments });
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
