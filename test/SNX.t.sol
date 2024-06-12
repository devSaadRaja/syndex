// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.17;

// import "forge-std/Test.sol";
// import {Utils} from "./Utils.sol";

// import {Synthetix} from "../src/contracts/Synthetix.sol";
// import {ProxyERC20} from "../src/contracts/ProxyERC20.sol";
// import {AddressResolver} from "../src/contracts/AddressResolver.sol";
// import {LegacyTokenState} from "../src/contracts/LegacyTokenState.sol";

// contract SNX is Test, Utils {
//     address public owner = vm.addr(1);
//     address public user1 = vm.addr(2);
//     address public reserveAddr = vm.addr(3);

//     ProxyERC20 public proxySNX;
//     Synthetix public synthetix;
//     LegacyTokenState public tokenStateSNX;
//     AddressResolver public addressResolver;

//     function setUp() public {
//         vm.startPrank(owner);

//         // ! DEPLOYMENTS

//         addressResolver = new AddressResolver(owner);

//         proxySNX = new ProxyERC20(owner);
//         tokenStateSNX = new LegacyTokenState(owner, address(synthetix));
//         synthetix = new Synthetix(
//             payable(address(proxySNX)),
//             address(tokenStateSNX),
//             owner,
//             0,
//             address(addressResolver)
//         );

//         // ! SETUP

//         proxySNX.updateTarget(address(synthetix));
//         tokenStateSNX.linkContract(address(synthetix));

//         vm.stopPrank();

//         // vm.startPrank(address(synthetix));
//         // tokenStateSNX.setBalanceOf(owner, 1000 ether);
//         // tokenStateSNX.setBalanceOf(user1, 1000 ether);
//         // vm.stopPrank();
//     }

//     function testBlacklist() public {
//         vm.startPrank(owner);
//         synthetix.updateBlacklist(user1, true);
//         vm.stopPrank();
//         vm.startPrank(user1);
//         vm.expectRevert("Address is blacklisted");
//         proxySNX.transfer(reserveAddr, 1 ether);
//         vm.stopPrank();
//     }
// }
