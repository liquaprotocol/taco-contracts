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
import {Helper} from "./Helper.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DepolyScript is Script, Helper {
    Router public router;
    WETH9 public weth;
    EVMClient public evmClient;
    OnRamp public onRamp;
    OffRamp public offRamp;


    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256 donPrivateKey = vm.envUint("BACKEND_KEY");

        address blessDon = vm.addr(donPrivateKey);


        address[] memory allowlist;

        // uint64 sourceChain = uint64(block.chainid);

        // destChains
        uint64[] memory destChains = new uint64[](2);
        destChains[0] = uint64(167008);
        destChains[1] = uint64(11155111);

        weth = new WETH9();

        // Deploying the contracts
        router = new Router(address(weth));
        evmClient = new EVMClient(router, address(0));
        TokenPool tokenPool = new LockReleaseTokenPool(IERC20(weth), allowlist, true);
        onRamp = new OnRamp(new Client.PoolUpdate[](0));
        offRamp = new OffRamp();


        // depositing the weth
        weth.deposit{value: 1 ether}();



        // Enabling the chains
        evmClient.enableChain(destChains[0], bytes("taiko testnet"));
        evmClient.enableChain(destChains[1], bytes("sepolia testnet"));
        // ----------------------------



        // Adding the pools
        Client.PoolUpdate[] memory targetPoolUpdates = new Client.PoolUpdate[](2);
        // for (uint256 i = 0; i < 2; i++) {
        //     (address destToken,) = getDummyTokensFromNetwork(SupportedNetworks.ETHEREUM_SEPOLIA);
        //     targetPoolUpdates[i] = Client.PoolUpdate(destToken, address(tokenPool));
        // }
        (address destToken,) = getDummyTokensFromNetwork(SupportedNetworks.ETHEREUM_SEPOLIA);
        (address destToken2,) = getDummyTokensFromNetwork(SupportedNetworks.KATLA_TAIKO);
        targetPoolUpdates[0] = Client.PoolUpdate(destToken, address(tokenPool));
        targetPoolUpdates[1] = Client.PoolUpdate(destToken2, address(tokenPool));

        offRamp.applyPoolUpdates(new Client.PoolUpdate[](0), targetPoolUpdates);
        offRamp.blessDone(blessDon, true);
        // ----------------------------


        // OnRamp pool updates
        Client.PoolUpdate[] memory poolUpdates = new Client.PoolUpdate[](1);
        poolUpdates[0] = Client.PoolUpdate(address(weth), address(tokenPool));
        onRamp.applyPoolUpdates(new Client.PoolUpdate[](0), poolUpdates);



        // Adding the onRamps and offRamps
        Router.OnRamp[] memory onRamps = new Router.OnRamp[](2);
        Router.OffRamp[] memory offRamps = new Router.OffRamp[](2);
        for (uint256 i = 0; i < 2; i++) {
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

        vm.stopBroadcast();
    }
}
