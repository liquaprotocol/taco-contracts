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
import {Helper} from "./utils/Helper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DepolyScript is Script, Helper {
    Router public router;
    WETH9 public weth;
    EVMClient public evmClient;
    OnRamp public onRamp;
    OffRamp public offRamp;
    PriceFeed public priceFeed;

    uint256 public constant chainCount = 2;

    uint256 public constant blessDonCount = 3;


    // ----------------------------
    address[blessDonCount] public blessDon = [
        0x9fccc08e4Ab9CF4688a219194DC4dDab6483e3E3,
        0xcE1Ca0467Ca4522Fa37e0528Ec35825595Be1214,
        0x5663477983D91838462A5D2132affda5A9C23112
    ];

    address public priceFeedProvider = 0x816F9b80b89ea57F4512ca420108d40bB48cD096;


    function getWeth() public returns (WETH9) {
        if (networkInfo[uint64(block.chainid)].weth != address(0)) {
            return WETH9(payable(networkInfo[uint64(block.chainid)].weth));
        }
        weth = new WETH9();
        console2.log("weth", address(weth));
        return weth;
    }


    function getPriceFeed() public returns (PriceFeed) {
        if (networkInfo[uint64(block.chainid)].priceFeed != address(0)) {
            return PriceFeed(networkInfo[uint64(block.chainid)].priceFeed);
        }
        priceFeed = new PriceFeed(
            new address[](0), new address[](0)
        );
        console2.log("priceFeed", address(priceFeed));

        return priceFeed;
    }

    function getWethTokenPool(address token_) public returns (TokenPool) {
        if (networkInfo[uint64(block.chainid)].wethTokenPool != address(0)) {
            return TokenPool(networkInfo[uint64(block.chainid)].wethTokenPool);
        }
        TokenPool tokenPool = new LockReleaseTokenPool(IERC20(token_), new address[](0), true);
        console2.log("tokenPool", address(tokenPool));
        return tokenPool;
    }


    function setUp() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // destChains
        uint64[] memory destChains = new uint64[](chainCount);
        destChains[0] = uint64(167008);
        destChains[1] = uint64(11155111);

        weth = getWeth();
        priceFeed = getPriceFeed();
        
        // Deploying the contracts
        router = new Router(address(weth));
        evmClient = new EVMClient(router, address(0));
        TokenPool tokenPool = getWethTokenPool(address(weth));
        onRamp = new OnRamp(new Client.PoolUpdate[](0), address(priceFeed));
        offRamp = new OffRamp();

        // Enabling the chains
        for (uint256 i = 0; i < chainCount; i++) {
            evmClient.enableChain(destChains[i], bytes("test"));
        }
        // ----------------------------



        // Adding the pools
        Client.PoolUpdate[] memory targetPoolUpdates = new Client.PoolUpdate[](1);
        // FIXME: This is a hack, we need to get the destChain from the router
        uint64 destChain = uint64(block.chainid) == destChains[0] ? destChains[1] : destChains[0];
        targetPoolUpdates[0] = Client.PoolUpdate(networkInfo[destChain].weth, address(tokenPool));

        offRamp.applyPoolUpdates(new Client.PoolUpdate[](0), targetPoolUpdates);
        for (uint256 i = 0; i < blessDonCount; i++) {
            offRamp.blessDone(blessDon[i], true);
        }
        // ----------------------------


        // OnRamp pool updates
        Client.PoolUpdate[] memory poolUpdates = new Client.PoolUpdate[](1);
        poolUpdates[0] = Client.PoolUpdate(address(weth), address(tokenPool));
        onRamp.applyPoolUpdates(new Client.PoolUpdate[](0), poolUpdates);



        // Adding the onRamps and offRamps
        Router.OnRamp[] memory onRamps = new Router.OnRamp[](2);
        Router.OffRamp[] memory offRamps = new Router.OffRamp[](2);
        for (uint256 i = 0; i < chainCount; i++) {
            onRamps[i] = Router.OnRamp(destChains[i], address(onRamp));
            offRamps[i] = Router.OffRamp(destChains[i], address(offRamp));
        }

        router.applyRampUpdates(onRamps, new Router.OffRamp[](0), offRamps);
        // ----------------------------



        // Adding the token pools
        TokenPool.RampUpdate[] memory onRampUpdates = new TokenPool.RampUpdate[](1);
        TokenPool.RampUpdate[] memory offRampUpdates = new TokenPool.RampUpdate[](1);

        onRampUpdates[0] = TokenPool.RampUpdate(address(onRamp), true);
        offRampUpdates[0] = TokenPool.RampUpdate(address(offRamp), true);

        tokenPool.applyRampUpdates(onRampUpdates, offRampUpdates);
        // ----------------------------
    }

    function run() public {

        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // address owner = vm.addr(deployerPrivateKey);



        // Client.EVMTokenAmount memory amount = Client.EVMTokenAmount(address(weth), 1 wei);

        // weth.approve(address(evmClient), 1 wei);


        // uint256 fee = evmClient.getFee(uint64(block.chainid), owner, amount);

        // console2.log("fee", fee);



        // bytes32 messageId = evmClient.sendToken{value: fee}(uint64(block.chainid), owner, amount);

        // console2.log("messageId:");
        // console2.logBytes32(messageId);
        
    }
}