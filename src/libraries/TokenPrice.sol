// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library TokenPrice {
    struct PriceUpdates {
        TokenPriceUpdate[] tokenPriceUpdates;
        GasPriceUpdate[] gasPriceUpdates;
    }

    /// @notice USD value of token price in Wei
    struct TokenPriceUpdate {
        address token; // Token contract address
        uint224 tokenPriceUSDWei; // 1 USD = 1e18 USDWei
    }

    /// @notice Gas price for a given chain in Wei
    struct GasPriceUpdate {
        uint64 destChainSelector; // Destination chain selector
        uint224 gasFeeUSDWei; // Gas fee in the unit of 1e18 USDWei
    }

    /// @notice A timestamed uint224 value to fit into 256 bits
    struct TimestampedValuePacked {
        uint224 value;
        uint32 timestamp;
    }
}
