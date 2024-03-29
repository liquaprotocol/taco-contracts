// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TokenPrice} from "../libraries/TokenPrice.sol";

interface IPriceFeed {
    /// @notice Returns the the current nonce for a receiver.
    /// @param token The sender address
    /// @return nonce The nonce value belonging to the sender address.
    function getTokenPrice(
        address token
    ) external view returns (TokenPrice.TimestampedValuePacked memory);

    /// @notice Get gasPrice in USD 1e18 decimals for a given destination chain.
    /// @param destChainSelector The destination chain to get the price for
    /// @return gasPrice
    function getDestChainGasPrice(
        uint64 destChainSelector
    ) external view returns (TokenPrice.TimestampedValuePacked memory);


    /// @notice Update the price for given tokens and gas prices for given chains.
    /// @param priceUpdates The price updates to apply.
    function updatePrices(TokenPrice.PriceUpdates memory priceUpdates) external;


}
