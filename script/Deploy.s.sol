// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {Issuer} from "../src/contracts/Issuer.sol";
import {Proxyable} from "../src/contracts/Proxyable.sol";
import {Synthetix} from "../src/contracts/Synthetix.sol";
import {ProxyERC20} from "../src/contracts/ProxyERC20.sol";
import {TokenState} from "../src/contracts/TokenState.sol";
import {Staking} from "../src/contracts/staking/Staking.sol";
import {SystemStatus} from "../src/contracts/SystemStatus.sol";
import {MixinResolver} from "../src/contracts/MixinResolver.sol";
import {ExchangeRates} from "../src/contracts/ExchangeRates.sol";
import {SupplySchedule} from "../src/contracts/SupplySchedule.sol";
import {AddressResolver} from "../src/contracts/AddressResolver.sol";
import {AggregatorCollateral} from "../src/contracts/AggregatorCollateral.sol";

import {ISynthetix} from "../src/interfaces/ISynthetix.sol";

contract DeployScript is Script {
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Factory factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bytes32[] public names;
    address[] public addresses;

    Issuer public issuer;
    ProxyERC20 public proxySNX;
    Synthetix public synthetix;
    TokenState public tokenState;
    SystemStatus public systemStatus;
    ExchangeRates public exchangeRates;
    AddressResolver public addressResolver;
    AggregatorCollateral public aggregatorCollateral;

    Staking public staking;

    function setUp() public {}

    function run() public {
        address deployer = 0xE536B4D7cf1e346D985cEe807e16B1b11B019976;
        address user = 0xc5Fa3B9D1C223E96eC77CB48880eeBeb9DaB4ad7;
        address treasury = 0x35D9466FFa2497fa919203809C2F150F493A0f73;

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        // ? DEPLOYMENTS ---

        systemStatus = new SystemStatus(deployer);
        addressResolver = new AddressResolver(deployer);
        issuer = new Issuer(deployer, address(addressResolver));
        aggregatorCollateral = new AggregatorCollateral(
            address(addressResolver)
        );
        exchangeRates = new ExchangeRates(deployer, address(addressResolver));
        proxySNX = new ProxyERC20(deployer);
        tokenState = new TokenState(deployer, address(synthetix));
        synthetix = new Synthetix(
            payable(address(proxySNX)),
            address(tokenState),
            deployer,
            100_000_000 ether,
            address(addressResolver)
        );
        staking = new Staking(address(proxySNX), address(proxySNX));

        // ? SETUP ---

        // // issuer.addSynth(address(synthsUSD));
        // // issuer.addSynth(address(synthsETH));

        // exchangeRates.addAggregator("SNX", address(aggregatorCollateral));

        // proxySNX.updateTarget(Proxyable(address(synthetix)));

        // tokenState.linkContract(address(synthetix));

        // // factory.createPair(address(proxySNX), WETH);
        // // address pair = factory.getPair(address(proxySNX), WETH);
        // // taxable.setPool(pair, true);

        // ? TRANSACTIONS ---

        // names.push("AddressResolver");
        // addresses.push(address(addressResolver));
        // names.push("SystemStatus");
        // addresses.push(address(systemStatus));
        // // *
        // names.push("Issuer");
        // addresses.push(address(issuer));
        // names.push("ExchangeRates");
        // addresses.push(address(exchangeRates));
        // names.push("Synthetix");
        // addresses.push(address(synthetix));

        // addressResolver.loadAddresses(names, addresses);
        // for (uint i = 2; i < addresses.length; i++) {
        //     MixinResolver(addresses[i]).refreshCache();
        // }

        // // ---

        // synthetix.mint(deployer, 100_000_000 ether);

        // proxySNX.transfer(address(staking), 30 * 10 ** 18);

        // // proxySNX.approve(address(router), 50 * 10 ** 18);
        // // IERC20(WETH).approve(address(router), 50 * 10 ** 18);
        // // router.addLiquidity(
        // //     address(proxySNX),
        // //     WETH,
        // //     50 * 10 ** 18,
        // //     50 * 10 ** 18,
        // //     0,
        // //     0,
        // //     deployer,
        // //     block.timestamp + 10 minutes
        // // );

        vm.stopBroadcast();
    }
}
