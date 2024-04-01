// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";


import {Router} from "../src/Router.sol";
import {WETH9} from "../src/mock/weth.sol";
import {EVMClient} from "../src/EVMClient.sol";
import {OnRamp} from "../src/OnRamp.sol";
import {OffRamp} from "../src/OffRamp.sol";
import {LockReleaseTokenPool} from "../src/pools/LockReleaseTokenPool.sol";
import {TokenPool} from "../src/pools/TokenPool.sol";
import {Client} from "../src/libraries/Client.sol";


import {IPool} from "../src/interfaces/IPool.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {PriceFeed} from "../src/PriceFeed.sol";

import {TokenPrice} from "../src/libraries/TokenPrice.sol";

import {RateLimiter} from "../src/libraries/RateLimiter.sol";

contract CrossBridgeTest is Test {
    Router public router;
    WETH9 public weth;
    EVMClient public evmClient;
    OnRamp public onRamp;
    OffRamp public offRamp;
    PriceFeed public priceFeed;
    LockReleaseTokenPool public tokenPool;

    uint256 public constant chainCount = 1;


    address public owner = 0x25044d07b6BF88a84FaC422c49f8604000248A9A;

    event SendRequested(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address indexed sender,
        address receiver,
        uint256 gasLimit,
        address feeToken,
        uint256 feeTokenAmount,
        address token,
        uint256 amount
    );

    function createUsers(uint256 userNum)
        public
        returns (address[] memory)
    {
        address[] memory users = new address[](userNum);

        for (uint256 i = 0; i < userNum; i++) {
            // This will create a new address using `keccak256(i)` as the private key
            address user = vm.addr(uint256(keccak256(abi.encodePacked(i))));
            vm.deal(user, 100 ether);
            users[i] = user;
        }

        return users;
    }


    

    function setUp() public {
        address[] memory allowlist;

        vm.startPrank(owner);

        vm.deal(owner, 100 ether);


        // uint64 sourceChain = uint64(block.chainid);

        // destChains
        uint64[] memory destChains = new uint64[](chainCount);
        destChains[0] = uint64(block.chainid);

        weth = new WETH9();


        // Adding the price providers
        address[] memory priceProvidersToAdd = new address[](1);

        priceProvidersToAdd[0] = address(owner);

        // Adding the price feed
        address[] memory tokens = new address[](1);
        tokens[0] = address(weth);

        priceFeed = new PriceFeed(priceProvidersToAdd, tokens);

        // Updating the prices
        TokenPrice.TokenPriceUpdate[] memory tokenPriceUpdates = new TokenPrice.TokenPriceUpdate[](1);
        tokenPriceUpdates[0] = TokenPrice.TokenPriceUpdate(address(weth), 5000 ether);
        TokenPrice.GasPriceUpdate[] memory gasPriceUpdates = new TokenPrice.GasPriceUpdate[](1);
        gasPriceUpdates[0] = TokenPrice.GasPriceUpdate(destChains[0], 5000 * 10 gwei );


        TokenPrice.PriceUpdates memory priceUpdates = TokenPrice.PriceUpdates(
            tokenPriceUpdates,
            gasPriceUpdates
        );

        priceFeed.updatePrices(priceUpdates);


        // Deploying the contracts
        router = new Router(address(weth));
        evmClient = new EVMClient(router, address(0));
        tokenPool = new LockReleaseTokenPool(IERC20(weth), allowlist, true);
        onRamp = new OnRamp(new Client.PoolUpdate[](0), address(priceFeed), address(router));
        offRamp = new OffRamp();


        // depositing the weth
        weth.deposit{value: 10 ether}();

        tokenPool.setRebalancer(address(owner));



        // Enabling the chains
        for (uint256 i = 0; i < chainCount; i++) {
            onRamp.enableChain(destChains[i], true);
        }

        onRamp.setTokenTransferFeeConfig(
            address(weth),
            0, 0, 1, 0
        );
        // ----------------------------



        // Adding the pools
        Client.PoolUpdate[] memory targetPoolUpdates = new Client.PoolUpdate[](1);
        targetPoolUpdates[0] = Client.PoolUpdate(address(weth), address(tokenPool));

        offRamp.applyPoolUpdates(new Client.PoolUpdate[](0), targetPoolUpdates);
        offRamp.blessDone(owner, true);
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

    function test_updatePriceProviders() public {
        address[] memory priceProvidersToRemove = new address[](1);

        priceProvidersToRemove[0] = owner;

        assert(priceFeed.getPriceProviders().length == 1);

        priceFeed.updatePriceProviders(createUsers(1), priceProvidersToRemove);

        address[] memory providers = priceFeed.getPriceProviders();


        assert(providers.length == 1);

    }

    function test_update_tokens() public {
        address weth2 = address(new WETH9());

        address[] memory tokens = new address[](1);

        tokens[0] = weth2;

        priceFeed.updateTokens(tokens, new address[](0));

        assert(priceFeed.getTokenPrice(weth2).timestamp == block.timestamp);

        priceFeed.updateTokens(new address[](0), tokens);

        assert(priceFeed.getTokenPrice(weth2).timestamp == 0);


    }

}
