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
        priceFeed = PriceFeed(0x9C47ac009fd21d61c2EcC40eD29fcF8E6f228B4d);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = vm.addr(deployerPrivateKey);


        // get price

        TokenPrice.TimestampedValuePacked memory res = priceFeed.getTokenPrice(0xb9f56e3659f927C54220a5E6Ded46162dD826A08);

        TokenPrice.TimestampedValuePacked memory res2 = priceFeed.getDestChainGasPrice(11155111);

        console2.log("timestamp:", res.timestamp);
        console2.log("value:", res.value);

        console2.log("----------------------");

        console2.log("timestamp:", res2.timestamp);
        console2.log("value:", res2.value);



        // () = priceFeed.getTokenPrice(0xb9f56e3659f927C54220a5E6Ded46162dD826A08);

        // updatePriceProviders(priceProvidersToAdd, new address[](0));

        
        // ----------------------------

        vm.stopBroadcast();
    }
}