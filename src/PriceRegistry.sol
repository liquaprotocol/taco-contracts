// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPriceRegistry} from "./interfaces/IPriceRegistry.sol";
import {TokenPrice} from "./libraries/TokenPrice.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice The PriceRegistry contract will store the current token price in USD
/// and the gas price in USD for a given destination chain.abi
contract PriceRegistry is IPriceRegistry, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event PriceProviderAdd(address indexed priceProvider);
    event PriceProviderRemove(address indexed priceProvider);

    /// @dev The gas price per unit of gas for a given destination chain, in USD with 18 decimals.
    /// Multiple gas prices can be encoded into the same value.
    /// Logic to parse the price components is chain-specific thus live in OnRamp.
    /// @dev Price of 1e18 is 1 USD. Examples:
    ///     Very Expensive:   1 unit of gas costs 1 USD                  -> 1e18
    ///     Expensive:        1 unit of gas costs 0.1 USD                -> 1e17
    ///     Cheap:            1 unit of gas costs 0.000001 USD           -> 1e12
    mapping(uint64 destChainSelector => TokenPrice.TimestampedValuePacked price)
        private s_gasFeeByDestChain;

    /// @dev The price of each token, in USD with 18 decimals,
    /// per 1e18 devided by the decimal of the smallest token units
    ///     1 USDC = 1.00 USD per full token, each full token is 1e6 units -> 1 * 1e18 * 1e18 / 1e6 = 1e30
    ///     1 ETH = 2,000 USD per full token, each full token is 1e18 units -> 2000 * 1e18 * 1e18 / 1e18 = 2_000e18
    mapping(address token => TokenPrice.TimestampedValuePacked price)
        private s_tokenPrice;

    // Price provider are allowed to update the price
    EnumerableSet.AddressSet private s_priceProviders;

    constructor(
        address[] memory priceProviders,
        address[] memory tokens
    ) Ownable(msg.sender) {
        _updatePriceProvders(priceProviders, new address[](0));
        // _updateTokens(tokens, new address[](0));
    }

    function _updatePriceProvders(
        address[] memory priceProvidersToAdd,
        address[] memory priceProvidersToRemove
    ) private {
        for (uint256 i = 0; i < priceProvidersToAdd.length; ++i) {
            if (s_priceProviders.add(priceProvidersToAdd[i])) {
                emit PriceProviderAdd(priceProvidersToAdd[i]);
            }
        }
        for (uint256 i = 0; i < priceProvidersToRemove.length; ++i) {
            if (s_priceProviders.remove(priceProvidersToRemove[i])) {
                emit PriceProviderRemove(priceProvidersToRemove[i]);
            }
        }
    }

    // function _updateTokens(
    //     address[] memory tokensToAdd,
    //     address[] memory tokensToRemove
    // ) private {
    //     for (uint256 i = 0; i < tokensToAdd.length; ++i) {
    //         if ()
    //     }

    //     for (uint256 i = 0; i < tokensToRemove.length; ++i) {}
    // }

    function getTokenPrice(
        address token
    ) public view override returns (TokenPrice.TimestampedValuePacked memory) {
        return s_tokenPrice[token];
    }

    function getDestChainGasPrice(
        uint64 destChainSelector
    )
        external
        view
        override
        returns (TokenPrice.TimestampedValuePacked memory)
    {
        return s_gasFeeByDestChain[destChainSelector];
    }

    /// @notice Get the list of price providers.
    /// @return Addresses of the price providers.
    function getPriceProviders() external view returns (address[] memory) {
        return s_priceProviders.values();
    }
}
