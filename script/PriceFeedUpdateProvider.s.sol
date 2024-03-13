// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {WETH9} from "../src/mock/weth.sol";
import {Router} from "../src/Router.sol";
import {EVMClient} from "../src/EVMClient.sol";
import {OnRamp} from "../src/OnRamp.sol";
import {OffRamp} from "../src/OffRamp.sol";
import {LockReleaseTokenPool} from "../src/pools/LockReleaseTokenPool.sol";
import {TokenPool} from "../src/pools/TokenPool.sol";
import {Client} from "../src/libraries/Client.sol";

import {PriceFeed} from "../src/PriceFeed.sol";


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TokenPrice} from "../src/libraries/TokenPrice.sol";


contract DepolyScript is Script {
    WETH9 public weth;
    PriceFeed public priceFeed;

    uint256 public constant chainCount = 2;


    function setUp() public {
        priceFeed = PriceFeed(0xca4dF7B3fCd903315b2937422E80144181a90299);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = vm.addr(deployerPrivateKey);


        // Adding the price providers
        address[] memory priceProvidersToAdd = new address[](1);

        priceProvidersToAdd[0] = address(0x816F9b80b89ea57F4512ca420108d40bB48cD096);



        priceFeed.updatePriceProviders(priceProvidersToAdd, new address[](0));

        
        // ----------------------------

        vm.stopBroadcast();
    }
}