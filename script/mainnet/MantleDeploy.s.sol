// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {WETH9} from "../../src/mock/weth.sol";
import {Router} from "../../src/Router.sol";
import {EVMClient} from "../../src/EVMClient.sol";
import {OnRamp} from "../../src/OnRamp.sol";
import {OffRamp} from "../../src/OffRamp.sol";
import {LockReleaseTokenPool} from "../../src/pools/LockReleaseTokenPool.sol";
import {TokenPool} from "../../src/pools/TokenPool.sol";
import {Client} from "../../src/libraries/Client.sol";

import {PriceFeed} from "../../src/PriceFeed.sol";
import {TokenPrice} from "../../src/libraries/TokenPrice.sol";

import {Helper} from "../utils/Helper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MantleDeployScript is Script, Helper {
    Router public router;
    WETH9 public weth;
    EVMClient public evmClient;
    OnRamp public onRamp;
    OffRamp public offRamp;
    PriceFeed public priceFeed;
    uint64 public destChain = uint64(10);


    uint256 public constant chainCount = 1;

    uint256 public constant blessDonCount = 4;

    uint256 public constant priceProvideCount = 2;

    address public owner;

    address public wnmt = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8;

    error InvalidChain();


    // ----------------------------
    address[blessDonCount] public blessDon = [
        0xb8E8AE19d6dE85908a386EEf6f87cABbF1450cc7,
        0xfcc1B127f6A3C2D5308Ae2Ff881F1FBE5700C9e4,
        0x21cA2F84FAb68aeA2340aF800eC5d29e26De2933,
        0xb16b50a9da586A9C760d5D08902AA25BD3B8C2Ff
    ];

    address[priceProvideCount] public priceProvides = [
        0xC59A1898a72A4e14d3131Dce67D4F63d6442F72F,
        0xb16b50a9da586A9C760d5D08902AA25BD3B8C2Ff
    ];

    function getWeth() public returns (WETH9) {
        if (networkInfo[uint64(block.chainid)].weth != address(0)) {
            return WETH9(payable(networkInfo[uint64(block.chainid)].weth));
        }
        weth = new WETH9();
        console2.log("weth:", address(weth));
        return weth;
    }


    function getPriceFeed() public returns (PriceFeed) {
        if (networkInfo[uint64(block.chainid)].priceFeed != address(0)) {
            return PriceFeed(networkInfo[uint64(block.chainid)].priceFeed);
        }

        address[] memory priceProvidersToAdd = new address[](priceProvideCount);
        for (uint256 i = 0; i < priceProvideCount; i++) {
            priceProvidersToAdd[i] = priceProvides[i];
        }
        // Adding the price feed
        address[] memory tokens = new address[](1);
        tokens[0] = address(weth);
        priceFeed = new PriceFeed(
            priceProvidersToAdd, tokens
        );
        console2.log("priceFeed:", address(priceFeed));

        return priceFeed;
    }

    function getWethTokenPool(address token_) public returns (LockReleaseTokenPool) {
        if (networkInfo[uint64(block.chainid)].wethTokenPool != address(0)) {
            return LockReleaseTokenPool(networkInfo[uint64(block.chainid)].wethTokenPool);
        }
        LockReleaseTokenPool tokenPool = new LockReleaseTokenPool(IERC20(token_), new address[](0), true);
        console2.log("wethTokenPool:", address(tokenPool));
        return tokenPool;
    }


    function setUp() public {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        owner = vm.addr(deployerPrivateKey);

        // destChains
        uint64[] memory destChains = new uint64[](chainCount);
        destChains[0] = uint64(10);


        for (uint256 i = 0; i < chainCount; i++) {
            if (destChains[i] == uint64(block.chainid)) {
                revert InvalidChain();
            }
        }

        weth = getWeth();
        priceFeed = getPriceFeed();
        
        // Deploying the contracts
        if (block.chainid == 5000) {
            router = new Router(wnmt);
        } else {
            router = new Router(address(weth));
        }
        router.setTokenLimit(address(weth), 1 ether, 1 days);

        console2.log("router:", address(router));
        evmClient = new EVMClient(router, address(0));
        console2.log("evmClient:", address(evmClient));
        LockReleaseTokenPool tokenPool = getWethTokenPool(address(weth));
        onRamp = new OnRamp(new Client.PoolUpdate[](0), address(priceFeed), address(router));
        console2.log("onRamp:", address(onRamp));
        offRamp = new OffRamp();
        console2.log("offRamp:", address(offRamp));


        tokenPool.setRebalancer(address(owner));


        // Enabling the chains
        for (uint256 i = 0; i < chainCount; i++) {
            onRamp.enableChain(destChains[i], true);
        }

        onRamp.setTokenTransferFeeConfig(
            address(weth),
            1 gwei, 0, 1, 0
        );
        // ----------------------------

        // Update the price feed
        TokenPrice.TokenPriceUpdate[] memory tokenPriceUpdates = new TokenPrice.TokenPriceUpdate[](2);
        tokenPriceUpdates[0] = TokenPrice.TokenPriceUpdate(address(weth), 3300 ether);
        tokenPriceUpdates[1] = TokenPrice.TokenPriceUpdate(wnmt, 1 ether);
        TokenPrice.GasPriceUpdate[] memory gasPriceUpdates = new TokenPrice.GasPriceUpdate[](chainCount);
        for (uint256 i = 0; i < chainCount; i++) {
            gasPriceUpdates[i] = TokenPrice.GasPriceUpdate(destChains[i], 1 * 10 gwei);
        }

        TokenPrice.PriceUpdates memory priceUpdates = TokenPrice.PriceUpdates(
            tokenPriceUpdates,
            gasPriceUpdates
        );

        priceFeed.updatePrices(priceUpdates);


        // Adding the pools
        Client.PoolUpdate[] memory targetPoolUpdates = new Client.PoolUpdate[](chainCount);
        for (uint256 i = 0; i < chainCount; i++) {
            targetPoolUpdates[i] = Client.PoolUpdate(networkInfo[destChains[i]].weth, address(tokenPool));
        }

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
        Router.OnRamp[] memory onRamps = new Router.OnRamp[](chainCount);
        Router.OffRamp[] memory offRamps = new Router.OffRamp[](chainCount);
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

        // console2.log("chainid:", block.chainid);
        // 

        if (block.chainid != 5000) {
            weth.deposit{value:  1 wei}();
        }

        



        Client.EVMTokenAmount memory amount = Client.EVMTokenAmount(address(weth), 1 wei);

        weth.approve(address(evmClient), 1 wei);


        uint256 fee = evmClient.getFee(destChain, owner, amount);

        console2.log("fee", fee);


        bytes32 messageId = evmClient.sendToken{value: fee}(destChain, owner, amount);

        console2.log("messageId:");
        console2.logBytes32(messageId);
        
    }
}