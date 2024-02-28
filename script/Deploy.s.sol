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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DepolyScript is Script {
    Router public router;
    WETH9 public weth;
    EVMClient public evmClient;
    OnRamp public onRamp;
    OffRamp public offRamp;


    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = vm.addr(deployerPrivateKey);

        address backend = 0x9fccc08e4Ab9CF4688a219194DC4dDab6483e3E3;

        address[] memory allowlist;

        weth = new WETH9();
        router = new Router(address(weth));
        evmClient = new EVMClient(router, address(0));
        TokenPool tokenPool = new LockReleaseTokenPool(IERC20(weth), allowlist, true);


        Client.PoolUpdate[] memory poolUpdates = new Client.PoolUpdate[](1);
        poolUpdates[0] = Client.PoolUpdate(address(weth), address(tokenPool));
        evmClient.enableChain(uint64(11155111), bytes("sepolia"));
        evmClient.enableChain(uint64(167008), bytes("Katla"));

        onRamp = new OnRamp(poolUpdates);
        offRamp = new OffRamp();

        offRamp.applyPoolUpdates(new Client.PoolUpdate[](0), poolUpdates);
        offRamp.blessDone(backend, true);

        Router.OnRamp[] memory onRamps = new Router.OnRamp[](1);
        Router.OffRamp[] memory offRamps = new Router.OffRamp[](1);

        onRamps[0] = Router.OnRamp(uint64(block.chainid), address(onRamp));
        offRamps[0] = Router.OffRamp(uint64(block.chainid), address(offRamp));

        TokenPool.RampUpdate[] memory rampUpdates = new TokenPool.RampUpdate[](1);
        TokenPool.RampUpdate[] memory rampUpdates2 = new TokenPool.RampUpdate[](1);


        rampUpdates[0] = TokenPool.RampUpdate(address(onRamp), true);
        rampUpdates2[0] = TokenPool.RampUpdate(address(offRamp), true);

        router.applyRampUpdates(onRamps, new Router.OffRamp[](0), offRamps);
        tokenPool.applyRampUpdates(rampUpdates, rampUpdates2);


        weth.deposit{value: 0.1 ether}();


        vm.stopBroadcast();
    }
}
