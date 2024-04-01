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

import {TokenPrice} from "../src/libraries/TokenPrice.sol";

contract DepolyScript is Script, Helper {
    Router public router;
    WETH9 public weth;
    EVMClient public evmClient;
    OnRamp public onRamp;
    OffRamp public offRamp;
    PriceFeed public priceFeed;
    uint64 destChainId = 11155111;

    function setUp() public {
        weth = WETH9(payable(networkInfo[uint64(block.chainid)].weth));
        evmClient = EVMClient(payable(networkInfo[uint64(block.chainid)].evmClient));
        offRamp = OffRamp(payable(networkInfo[uint64(block.chainid)].offRamp));
    }

    function run() public {
        // MockDon();
        sendToken();
        
    }

    function sendToken() public {
         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = vm.addr(deployerPrivateKey);

        Client.EVMTokenAmount memory amount = Client.EVMTokenAmount(address(weth), 0.01 ether);

        weth.approve(address(evmClient), 900 ether);

        // priceFeed = PriceFeed(payable(networkInfo[uint64(block.chainid)].priceFeed));

        // TokenPrice.GasPriceUpdate[] memory gasPriceUpdates = new TokenPrice.GasPriceUpdate[](2);
        // // gasPriceUpdates[0] = TokenPrice.GasPriceUpdate(11155111, 40 * 1e18);
        // // gasPriceUpdates[1] = TokenPrice.GasPriceUpdate(167008, 40 * 1e18);
        // gasPriceUpdates[1] = TokenPrice.GasPriceUpdate(5003, 4 * 1e18);
        // TokenPrice.PriceUpdates memory priceUpdates = TokenPrice.PriceUpdates(new TokenPrice.TokenPriceUpdate[](0), gasPriceUpdates);

        // priceFeed.updatePrices(priceUpdates);


        uint256 fee = evmClient.getFee(destChainId, owner, amount);

        console2.log("fee", fee);



        bytes32 messageId = evmClient.sendToken{value: fee}(destChainId, owner, amount);

        console2.log("messageId:");
        console2.logBytes32(messageId);
    }

    function MockDon() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = vm.addr(deployerPrivateKey);

        bytes32 messageId = 0xb501f03c518d97a7974e62665d1ef823bd66fb9ec233ba85ea92922958d0e253;


        address sourceToken = networkInfo[destChainId].weth;

        Client.EVMTokenAmount memory amount = Client.EVMTokenAmount(sourceToken, 1 wei);


        offRamp.executeSingleMessage(Client.EVM2EVMMessage(
            destChainId,
            owner,
            owner,
            0,
            address(0),
            0,
            amount,
            messageId
        ), new bytes(0));

    }
}