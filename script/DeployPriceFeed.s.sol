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
        weth = WETH9(payable(0x3cFd763b341DfCC2B0C75bAd2120e0ad230B9eF3));
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = vm.addr(deployerPrivateKey);


        // Adding the price providers
        address[] memory priceProvidersToAdd = new address[](4);

        priceProvidersToAdd[0] = address(0x9fccc08e4Ab9CF4688a219194DC4dDab6483e3E3);
        priceProvidersToAdd[1] = address(0xcE1Ca0467Ca4522Fa37e0528Ec35825595Be1214);
        priceProvidersToAdd[2] = address(0x5663477983D91838462A5D2132affda5A9C23112);
        priceProvidersToAdd[3] = owner;

        // Adding the price feed
        address[] memory tokens = new address[](1);
        tokens[0] = address(weth);

        priceFeed = new PriceFeed(priceProvidersToAdd, tokens);



        // Updating the prices
        TokenPrice.TokenPriceUpdate[] memory tokenPriceUpdates = new TokenPrice.TokenPriceUpdate[](1);
        tokenPriceUpdates[0] = TokenPrice.TokenPriceUpdate(address(weth), 4000 ether);
        TokenPrice.GasPriceUpdate[] memory gasPriceUpdates = new TokenPrice.GasPriceUpdate[](1);
        gasPriceUpdates[0] = TokenPrice.GasPriceUpdate(uint64(11155111), 4000);


        TokenPrice.PriceUpdates memory priceUpdates = TokenPrice.PriceUpdates(
            tokenPriceUpdates,
            gasPriceUpdates
        );

        priceFeed.updatePrices(priceUpdates);

        
        // ----------------------------

        vm.stopBroadcast();
    }
}