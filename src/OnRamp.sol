// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPool} from "./interfaces/IPool.sol";
import {IOnRampClient} from "./interfaces/IOnRampClient.sol";
import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {Client} from "./libraries/Client.sol";
import {EnumerableMapAddresses} from "./libraries/EnumerableMapAddresses.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract OnRamp is IOnRampClient, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableMapAddresses for EnumerableMapAddresses.AddressToAddressMap;


    uint256 public constant MESSAGE_FIXED_BYTES = 32 * 17;
    uint256 public constant MESSAGE_FIXED_BYTES_PER_TOKEN = 32 * 4;

    address internal i_priceRegsitry;

    uint32 internal i_destGasOverhead = 100000;

    /// @dev The current nonce per sender.
    /// The offramp has a corresponding s_senderNonce mapping to ensure messages
    /// are executed in the same order they are sent.
    mapping(address sender => uint64 nonce) internal s_senderNonce;

    /// @dev The token transfer fee config (owner or fee admin can update)
    mapping(address token => TokenTransferFeeConfig)
        internal s_tokenTransferFeeConfig;

    /// @dev Struct to store the fee configuration for transferred token
    struct TokenTransferFeeConfig {
        uint32 minFeeUSDCents; // Minimum fee to charge per token tranfer. Unit: 0.01 USD
        uint32 maxFeeUSDCents; // Maximum fee to charge per token tranfer. Unit: 0.01 USD
        uint16 basePoints; // Basis points charged. Unit: 0.001% = 0.1bps
        uint32 destGasCharge; // Gas charged for the execution on the destination chain
    }

    struct DataAvailabilityConfig {
        uint32 destGasPerDataAvailabilityByte; // Gas charged for the data availability on the destination chain
        uint32 destDataAvailabilityOverheadGas; // Overhead gas charged for the data availability on the destination chain
        uint16 destDataAvailabilityMultiplierBps; // Multiplier for the data availability cost
    }

    DataAvailabilityConfig internal s_dynamicConfig;

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

    event PoolAdded(address token, address pool);
    event PoolRemoved(address token, address pool);

    error PoolDoesNotExist(address token);
    error TokenPoolMismatch();
    error InvalidTokenPoolConfig();
    error PoolAlreadyAdded();
    error UnsupportedToken(IERC20 token);

    EnumerableMapAddresses.AddressToAddressMap private s_poolsBySourceToken;

    constructor(Client.PoolUpdate[] memory tokensAndPools, address _priceRegsitry) Ownable(msg.sender) {
        _applyPoolUpdates(new Client.PoolUpdate[](0), tokensAndPools);
        i_priceRegsitry = _priceRegsitry;
    }

    function _getTokenTransferCost(
        address feeToken,
        uint224 feeTokenPrice,
        Client.EVMTokenAmount memory tokenAmount
    ) internal view returns (uint256 tokenTransferFeeUSDWei) {
        if (!s_poolsBySourceToken.contains(tokenAmount.token))
            revert UnsupportedToken(IERC20(tokenAmount.token));

        // calculate bpsFeeUSDWei
        uint256 bpsFeeUSDWei = 0;

        TokenTransferFeeConfig
            memory transferFeeConfig = s_tokenTransferFeeConfig[
                tokenAmount.token
            ];

        uint224 tokenPrice = 0;
        if (tokenAmount.token != feeToken) {
            tokenPrice = IPriceFeed(i_priceRegsitry).getTokenPrice(
                tokenAmount.token
            ).value;
        } else {
            tokenPrice = feeTokenPrice;
        }

        bpsFeeUSDWei =
            (tokenPrice * tokenAmount.amount * transferFeeConfig.basePoints) /
            1e23;

        uint256 minFeeUSDWei = uint256(transferFeeConfig.minFeeUSDCents) * 1e16;
        uint256 maxFeeUSDWei = uint256(transferFeeConfig.maxFeeUSDCents) * 1e16;

        if (bpsFeeUSDWei < minFeeUSDWei) {
            return minFeeUSDWei;
        } else if (bpsFeeUSDWei > maxFeeUSDWei) {
            return maxFeeUSDWei;
        }

        return bpsFeeUSDWei;
    }

    /// @notice Returns the estimated data availability cost of the message.
  /// @dev To save on gas, we use a single destGasPerDataAvailabilityByte value for both zero and non-zero bytes.
  /// @param dataAvailabilityGasPrice USD per data availability gas in 18 decimals.
  /// @param messageDataLength length of the data field in the message.
  /// @param tokenTransferBytesOverhead additional token transfer data passed to destination, e.g. USDC attestation.
  /// @return dataAvailabilityCostUSD36Decimal total data availability cost in USD with 36 decimals.
  function _getDataAvailabilityCost(
    uint112 dataAvailabilityGasPrice,
    uint256 messageDataLength,
    uint32 tokenTransferBytesOverhead
  ) internal view returns (uint256 dataAvailabilityCostUSD36Decimal) {
    // dataAvailabilityLengthBytes sums up byte lengths of fixed message fields and dynamic message fields.
    // Fixed message fields do account for the offset and length slot of the dynamic fields.
    uint256 dataAvailabilityLengthBytes = MESSAGE_FIXED_BYTES +
      messageDataLength +
      MESSAGE_FIXED_BYTES_PER_TOKEN +
      tokenTransferBytesOverhead;

    // destDataAvailabilityOverheadGas is a separate config value for flexibility to be updated independently of message cost.
    // Its value is determined by CCIP lane implementation, e.g. the overhead data posted for OCR.
    uint256 dataAvailabilityGas = (dataAvailabilityLengthBytes * s_dynamicConfig.destGasPerDataAvailabilityByte) +
      s_dynamicConfig.destDataAvailabilityOverheadGas;

    // dataAvailabilityGasPrice is in 18 decimals, destDataAvailabilityMultiplierBps is in 4 decimals
    // We pad 14 decimals to bring the result to 36 decimals, in line with token bps and execution fee.
    return
      ((dataAvailabilityGas * dataAvailabilityGasPrice) * s_dynamicConfig.destDataAvailabilityMultiplierBps) * 1e14;
  }

    function getFee(
        uint64 destChainSelector,
        Client.FromEVMMessage memory message
    ) external view override returns (uint256 fee) {

        require(s_poolsBySourceToken.contains(message.tokenAmount.token), "Unsupported token");
        require(block.timestamp + 1 days >= IPriceFeed(i_priceRegsitry).getTokenPrice(message.feeToken).timestamp, "Price not available");
        require(block.timestamp + 1 days >= IPriceFeed(i_priceRegsitry).getDestChainGasPrice(destChainSelector).timestamp, "Price not available");

        uint224 feeTokenPrice = IPriceFeed(i_priceRegsitry).getTokenPrice(message.feeToken).value;

        uint224 destChainGasPrice = IPriceFeed(i_priceRegsitry).getDestChainGasPrice(destChainSelector).value;

        Client.EVMTokenAmount memory tokenAmount = message.tokenAmount;

        // Charge the user based on basis points
        uint256 premiumFee = _getTokenTransferCost(
            message.feeToken,
            feeTokenPrice,
            tokenAmount
        );

        uint32 destGasOverhead = i_destGasOverhead;
        uint256 tokenTransferGas = _getTokenTransferCost(message.feeToken, feeTokenPrice, tokenAmount);
        uint256 executionFee = destChainGasPrice *
            (destGasOverhead + tokenTransferGas);

        uint256 dataAvailabilityFee = 0;
        return
            (premiumFee + executionFee + dataAvailabilityFee) / feeTokenPrice;
    }

    function getPoolBySourceToken(
        uint64 /*destChainSelector*/,
        IERC20 sourceToken
    ) public view override returns (IPool) {
        if (!s_poolsBySourceToken.contains(address(sourceToken)))
            revert UnsupportedToken(sourceToken);

        return IPool(s_poolsBySourceToken.get(address(sourceToken)));
    }

    function getSupportedTokens(
        uint64 /*destChainSelector*/
    ) external view returns (address[] memory) {
        address[] memory sourceTokens = new address[](
            s_poolsBySourceToken.length()
        );
        for (uint256 i = 0; i < sourceTokens.length; ++i) {
            (sourceTokens[i], ) = s_poolsBySourceToken.at(i);
        }
        return sourceTokens;
    }

    function getSenderNonce(address sender) public view returns (uint64 nonce) {
        return s_senderNonce[sender];
    }

    function forwardFromRouter(
        uint64 destChainSelector,
        Client.FromEVMMessage memory message,
        uint256 feeTokenAmount,
        address originalSender
    ) external override returns (bytes32 messageId) {
        if (s_senderNonce[originalSender] == 0) {
            s_senderNonce[originalSender] = getSenderNonce(originalSender) + 1;
        }
        messageId = keccak256(
            abi.encode(
                destChainSelector,
                message,
                feeTokenAmount,
                originalSender,
                s_senderNonce[originalSender]
            )
        );

        getPoolBySourceToken(
            destChainSelector,
            IERC20(message.tokenAmount.token)
        ).lock(
                originalSender,
                message.receiver,
                message.tokenAmount.amount,
                destChainSelector,
                bytes("") // any future extraArgs component would be added here
            );
        emit SendRequested(
            messageId,
            destChainSelector,
            originalSender,
            message.receiver,
            0,
            message.feeToken,
            feeTokenAmount,
            message.tokenAmount.token,
            message.tokenAmount.amount
        );

        return messageId;
    }

    function applyPoolUpdates(
        Client.PoolUpdate[] memory removes,
        Client.PoolUpdate[] memory adds
    ) external onlyOwner {
        _applyPoolUpdates(removes, adds);
    }

    function _applyPoolUpdates(
        Client.PoolUpdate[] memory removes,
        Client.PoolUpdate[] memory adds
    ) internal {
        for (uint256 i = 0; i < removes.length; ++i) {
            address token = removes[i].token;
            address pool = removes[i].pool;

            if (!s_poolsBySourceToken.contains(token))
                revert PoolDoesNotExist(token);
            if (s_poolsBySourceToken.get(token) != pool)
                revert TokenPoolMismatch();

            if (s_poolsBySourceToken.remove(token)) {
                emit PoolRemoved(token, pool);
            }
        }

        for (uint256 i = 0; i < adds.length; ++i) {
            address token = adds[i].token;
            address pool = adds[i].pool;

            if (token == address(0) || pool == address(0))
                revert InvalidTokenPoolConfig();
            if (token != address(IPool(pool).getToken()))
                revert TokenPoolMismatch();

            if (s_poolsBySourceToken.set(token, pool)) {
                emit PoolAdded(token, pool);
            } else {
                revert PoolAlreadyAdded();
            }
        }
    }

    function setPriceFeed(address _priceRegsitry) external onlyOwner {
        i_priceRegsitry = _priceRegsitry;
    }

    function setTokenTransferFeeConfig(
        address token,
        uint32 minFeeUSDCents,
        uint32 maxFeeUSDCents,
        uint16 basePoints,
        uint32 destGasCharge
    ) external onlyOwner {
        s_tokenTransferFeeConfig[token] = TokenTransferFeeConfig({
            minFeeUSDCents: minFeeUSDCents,
            maxFeeUSDCents: maxFeeUSDCents,
            basePoints: basePoints,
            destGasCharge: destGasCharge
        });
    }

    function setDestGasOverhead(uint32 destGasOverhead) external onlyOwner {
        i_destGasOverhead = destGasOverhead;
    }
}
