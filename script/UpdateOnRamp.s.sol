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
import {Helper} from "./utils/Helper.sol";

contract DepolyScript is Script, Helper {
    
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);



        uint256 chainCount = 2;

        // destChains
        uint64[] memory destChains = new uint64[](chainCount);
        destChains[0] = uint64(167008);
        destChains[1] = uint64(11155111);

        WETH9 weth = WETH9(payable(networkInfo[uint64(block.chainid)].weth));

        

        Router router = Router(payable(networkInfo[uint64(block.chainid)].router));

        PriceFeed priceFeed = PriceFeed(payable(networkInfo[uint64(block.chainid)].priceFeed));

        address tokenPool = networkInfo[uint64(block.chainid)].wethTokenPool;

        Client.PoolUpdate[] memory poolUpdates = new Client.PoolUpdate[](1);
        poolUpdates[0] = Client.PoolUpdate(address(weth), address(tokenPool));

        // Deploying the contracts
        OnRamp onRamp = OnRamp(0x71320dD08a45521c269ea7a37432973C7a57707f);
        // new OnRamp(poolUpdates, address(priceFeed));




        // Adding the onRamps and offRamps
        Router.OnRamp[] memory onRamps = new Router.OnRamp[](1);
        onRamps[0] = Router.OnRamp(destChains[0], address(onRamp));

        router.applyRampUpdates(onRamps, new Router.OffRamp[](0), new Router.OffRamp[](0));
        // ----------------------------



        // Adding the token pools
        // TokenPool.RampUpdate[] memory onRampUpdates = new TokenPool.RampUpdate[](1);

        // onRampUpdates[0] = TokenPool.RampUpdate(address(onRamp), true);


        // TokenPool(tokenPool).applyRampUpdates(onRampUpdates, new TokenPool.RampUpdate[](0));
        // ----------------------------

        vm.stopBroadcast();
    }
}