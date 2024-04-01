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

import {TokenPrice} from "../src/libraries/TokenPrice.sol";



import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Helper} from "./utils/Helper.sol";

contract DepolyScript is Script, Helper {

    Router public router;
    WETH9 public weth;
    EVMClient public evmClient;
    OnRamp public onRamp;
    OffRamp public offRamp;
    PriceFeed public priceFeed;
    TokenPool public tokenPool;

    uint256 public constant chainCount = 3;

    uint64[chainCount] public destChains = [
        167008,
        11155111,
        5003
    ];

    uint64 newChainId = 5003;


    
    function setUp() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        if (uint64(block.chainid) == newChainId) {
            return;
        }


        // Price Feed Update
        priceFeed = PriceFeed(payable(networkInfo[uint64(block.chainid)].priceFeed));
        TokenPrice.GasPriceUpdate[] memory gasPriceUpdates = new TokenPrice.GasPriceUpdate[](1);
        gasPriceUpdates[0] = TokenPrice.GasPriceUpdate(newChainId, 4000000000000000000);

        TokenPrice.PriceUpdates memory priceUpdates = TokenPrice.PriceUpdates(
            new TokenPrice.TokenPriceUpdate[](0),
            gasPriceUpdates
        );

        priceFeed.updatePrices(priceUpdates);


        // onRamps and offRamps Update
        router = Router(payable(networkInfo[uint64(block.chainid)].router));
        onRamp = OnRamp(payable(networkInfo[uint64(block.chainid)].onRamp));
        offRamp = OffRamp(payable(networkInfo[uint64(block.chainid)].offRamp));

        Router.OnRamp[] memory onRamps = new Router.OnRamp[](1);
        Router.OffRamp[] memory offRamps = new Router.OffRamp[](1);
        onRamps[0] = Router.OnRamp(newChainId, address(onRamp));
        offRamps[0] = Router.OffRamp(newChainId, address(offRamp));
        router.applyRampUpdates(onRamps, new Router.OffRamp[](0), offRamps);

        onRamp.enableChain(newChainId, true);


        // tokenPool Update
        tokenPool = TokenPool(payable(networkInfo[uint64(block.chainid)].wethTokenPool));

        Client.PoolUpdate[] memory targetPoolUpdates = new Client.PoolUpdate[](1);
        targetPoolUpdates[0] = Client.PoolUpdate(networkInfo[newChainId].weth, address(tokenPool));
        offRamp.applyPoolUpdates(new Client.PoolUpdate[](0), targetPoolUpdates);


    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);

        OffRamp sourceChainOffRamp = OffRamp(payable(networkInfo[uint64(block.chainid)].offRamp));

        sourceChainOffRamp.blessDone(owner, true);

        bytes32 messageId = 0xb501f03c518d97a7974e62665d1ef823bd66fb9ec233ba85ea92922958d0e256;


        // print getDestinationTokens
        IERC20[] memory destTokens = sourceChainOffRamp.getDestinationTokens();
        for (uint256 i = 0; i < destTokens.length; i++) {
            console2.log("destTokens:", address(destTokens[i]));
        }


        Client.EVMTokenAmount memory amount = Client.EVMTokenAmount(networkInfo[uint64(newChainId)].weth, 1 wei);


        sourceChainOffRamp.executeSingleMessage(Client.EVM2EVMMessage(
            newChainId,
            owner,
            owner,
            0,
            address(0),
            0,
            amount,
            messageId
        ), new bytes(0));
        

        vm.stopBroadcast();
    }
}