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

contract CrossBridgeTest is Test {
    Router public router;
    WETH9 public weth;
    EVMClient public evmClient;
    OnRamp public onRamp;
    OffRamp public offRamp;

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


    

    function setUp() public {
        address[] memory allowlist;

        vm.startPrank(owner);

        vm.deal(owner, 100 ether);

        weth = new WETH9();
        router = new Router(address(weth));
        evmClient = new EVMClient(router, address(0));
        TokenPool tokenPool = new LockReleaseTokenPool(IERC20(weth), allowlist, true);


        Client.PoolUpdate[] memory poolUpdates = new Client.PoolUpdate[](1);
        poolUpdates[0] = Client.PoolUpdate(address(weth), address(tokenPool));
        evmClient.enableChain(uint64(block.chainid), bytes("test"));

        onRamp = new OnRamp(poolUpdates);
        offRamp = new OffRamp();

        offRamp.applyPoolUpdates(new Client.PoolUpdate[](0), poolUpdates);
        offRamp.blessDone(owner, true);

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


        weth.deposit{value: 10 ether}();

    }

    function test_normal() public {

        uint256 balance = weth.balanceOf(owner);
        assert(balance == 10 ether);

        Client.EVMTokenAmount memory amount = Client.EVMTokenAmount(address(weth), 1 ether);

        weth.approve(address(evmClient), 1 ether);
        bytes32 messageId = evmClient.sendToken(uint64(block.chainid), owner, amount);


        assert(weth.balanceOf(owner) == 9 ether);


        Client.EVM2EVMMessage memory message = Client.EVM2EVMMessage(
            uint64(block.chainid),
            owner,
            owner,
            0,
            address(0),
            0,
            amount,
            messageId
        );

        offRamp.executeSingleMessage(message, new bytes(0));

        

        
        // vm.expectEmit(address(onRamp));
        // emit SendRequested(
        //     messageId,
        //     uint64(block.chainid),
        //     owner,
        //     owner,
        //     0,
        //     address(0),
        //     0,
        //     address(weth),
        //     1 ether
        // );


        assert(weth.balanceOf(owner) == 10 ether);






        


        // counter.increment();
        // assertEq(counter.number(), 1);
    }

}
