// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "./interfaces/IOffRamp.sol";
import "./interfaces/IPool.sol";

import {Client} from "./libraries/Client.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableMapAddresses} from "./libraries/EnumerableMapAddresses.sol";

contract OffRamp is IOffRamp, Ownable {
    using EnumerableMapAddresses for EnumerableMapAddresses.AddressToAddressMap;

    event PoolAdded(address indexed token, address indexed pool);
    event PoolRemoved(address indexed token, address indexed pool);

    event TokenHandlingError(bytes returnData);

    error UnsupportedToken(IERC20 token);
    error PoolDoesNotExist();
    error TokenPoolMismatch();
    error InvalidTokenPoolConfig();
    error PoolAlreadyAdded();
    error CanOnlySelfCall();
    error MessageIdAlreadyProcessed();

    EnumerableMapAddresses.AddressToAddressMap private s_poolsBySourceToken;
    EnumerableMapAddresses.AddressToAddressMap private s_poolsByDestToken;


  mapping(address sender => uint64 nonce) internal s_senderNonce;

  mapping(address => bool) public blessDones;

  mapping(bytes32 => bool) public processedMessages;

    constructor() Ownable(msg.sender) {}

    function getSenderNonce(address sender)
        external
        view
        override
        returns (uint64 nonce)
    {
        uint256 senderNonce = s_senderNonce[sender];

        return uint64(senderNonce);

    }

    function executeSingleMessage(
        Client.EVM2EVMMessage memory message,
        bytes memory offchainTokenData
    ) external OnlyBlessDones {

        if (processedMessages[message.messageId]) revert MessageIdAlreadyProcessed();
        
        _releaseOrMintToken(
                message.tokenAmount,
                message.sender,
                message.receiver,
                offchainTokenData
            );

        processedMessages[message.messageId] = true;
    }

    function getSupportedTokens()
        external
        view
        returns (IERC20[] memory sourceTokens)
    {
        sourceTokens = new IERC20[](s_poolsBySourceToken.length());
        for (uint256 i = 0; i < sourceTokens.length; ++i) {
            (address token, ) = s_poolsBySourceToken.at(i);
            sourceTokens[i] = IERC20(token);
        }
    }

    function getPoolBySourceToken(
        IERC20 sourceToken
    ) public view returns (IPool) {
        (bool success, address pool) = s_poolsBySourceToken.tryGet(
            address(sourceToken)
        );
        if (!success) revert UnsupportedToken(sourceToken);
        return IPool(pool);
    }

    function getDestinationToken(
        IERC20 sourceToken
    ) external view returns (IERC20) {
        return getPoolBySourceToken(sourceToken).getToken();
    }

    function getPoolByDestToken(
        IERC20 destToken
    ) external view returns (IPool) {
        (bool success, address pool) = s_poolsByDestToken.tryGet(
            address(destToken)
        );
        if (!success) revert UnsupportedToken(destToken);
        return IPool(pool);
    }

    function getDestinationTokens()
        external
        view
        returns (IERC20[] memory destTokens)
    {
        destTokens = new IERC20[](s_poolsByDestToken.length());
        for (uint256 i = 0; i < destTokens.length; ++i) {
            (address token, ) = s_poolsByDestToken.at(i);
            destTokens[i] = IERC20(token);
        }
    }

    function applyPoolUpdates(
        Client.PoolUpdate[] calldata removes,
        Client.PoolUpdate[] calldata adds
    ) external onlyOwner {
        for (uint256 i = 0; i < removes.length; ++i) {
            address token = removes[i].token;
            address pool = removes[i].pool;

            if (!s_poolsBySourceToken.contains(token))
                revert PoolDoesNotExist();
            if (s_poolsBySourceToken.get(token) != pool)
                revert TokenPoolMismatch();

            s_poolsBySourceToken.remove(token);
            s_poolsByDestToken.remove(address(IPool(pool).getToken()));

            emit PoolRemoved(token, pool);
        }

        for (uint256 i = 0; i < adds.length; ++i) {
            address token = adds[i].token;
            address pool = adds[i].pool;

            if (token == address(0) || pool == address(0))
                revert InvalidTokenPoolConfig();
            if (s_poolsBySourceToken.contains(token)) revert PoolAlreadyAdded();

            s_poolsBySourceToken.set(token, pool);
            s_poolsByDestToken.set(address(IPool(pool).getToken()), pool);

            emit PoolAdded(token, pool);
        }
    }

    function blessDone(address done, bool flag) external onlyOwner {
        blessDones[done] = flag;
    }

    function _releaseOrMintToken(
        Client.EVMTokenAmount memory sourceTokenAmount,
        address originalSender,
        address receiver,
        bytes memory offchainTokenData
    ) internal returns (Client.EVMTokenAmount memory) {
        IPool pool = getPoolBySourceToken(IERC20(sourceTokenAmount.token));
        

        pool.release(originalSender, receiver, sourceTokenAmount.amount, uint64(block.chainid) , offchainTokenData);


        return sourceTokenAmount;
    }

    modifier OnlyBlessDones() {
        require(blessDones[msg.sender], "OffRamp: Not blessed");
        _;
    }
}
