// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Client {
    struct EVMTokenAmount {
        address token; // token address on the local chain.
        uint256 amount; // Amount of tokens.
    }

    struct FromEVMMessage {
        address receiver; // abi.encode(receiver address) for dest EVM chains
        bytes data;
        EVMTokenAmount tokenAmount;
        address feeToken;
    }

    struct ToEVMMessage {
        bytes32 messageId;
        uint64 sourceChainSelector;
        address sender;
        bytes data;
        EVMTokenAmount destTokenAmount;
    }

    struct PoolUpdate {
        address token;
        address pool;
    }

    struct EVM2EVMMessage {
        uint64 sourceChainSelector;
        address sender;
        address receiver;
        uint256 gasLimit;
        address feeToken;
        uint256 feeTokenAmount;
        EVMTokenAmount tokenAmount;
        bytes32 messageId;
    }
}
