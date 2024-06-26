// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IRouterClient} from "./interfaces/IRouterClient.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {IOnRampClient} from "./interfaces/IOnRampClient.sol";
import {IWrappedNative} from "./interfaces/IWrappedNative.sol";

import {Client} from "./libraries/Client.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Router
/// @notice This is the entry point for the end user wishing to send data across chains.
/// @dev This contract is used as a router for both on-ramps and off-ramps
contract Router is IRouter, IRouterClient, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.UintSet;

  error FailedToSendValue();
  error InvalidRecipientAddress(address to);
  error OffRampMismatch(uint64 chainSelector, address offRamp);
  error BadARMSignal();
  error TooManyTokens(address token, uint256 amount);

  event OnRampSet(uint64 indexed destChainSelector, address onRamp);
  event OffRampAdded(uint64 indexed sourceChainSelector, address offRamp);
  event OffRampRemoved(uint64 indexed sourceChainSelector, address offRamp);
  event MessageExecuted(bytes32 messageId, uint64 sourceChainSelector, address offRamp, bytes32 calldataHash);
  

  struct OnRamp {
    uint64 destChainSelector;
    address onRamp;
  }

  struct OffRamp {
    uint64 sourceChainSelector;
    address offRamp;
  }

  struct TokenLimit {
    uint256 amount;
    uint256 updatedTimestamp;
  }

  // DYNAMIC CONFIG
  address private s_wrappedNative;
  mapping(uint256 destChainSelector => address onRamp) private s_onRamps;

  mapping(address token => TokenLimit limit) private s_tokenLimits;

  mapping(address user => mapping(address token => TokenLimit limit)) private s_userTokenLimits;
  
  EnumerableSet.UintSet private s_chainSelectorAndOffRamps;

  constructor(address wrappedNative) Ownable(msg.sender) {
    s_wrappedNative = wrappedNative;
    s_tokenLimits[wrappedNative] = TokenLimit({amount: 1 ether, updatedTimestamp: 1 days});
  }

  /// @inheritdoc IRouterClient
  function getFee(
    uint64 destinationChainSelector,
    Client.FromEVMMessage memory message
  ) external view returns (uint256 fee) {
    if (message.feeToken == address(0)) {
      // For empty feeToken return native quote.
      message.feeToken = address(s_wrappedNative);
    }
    address onRamp = s_onRamps[destinationChainSelector];
    if (onRamp == address(0)) revert UnsupportedDestinationChain(destinationChainSelector);
    return IOnRampClient(onRamp).getFee(destinationChainSelector, message);
  }

  /// @inheritdoc IRouterClient
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory) {
    if (!isChainSupported(chainSelector)) {
      return new address[](0);
    }
    return IOnRampClient(s_onRamps[uint256(chainSelector)]).getSupportedTokens(chainSelector);
  }

  /// @inheritdoc IRouterClient
  function isChainSupported(uint64 chainSelector) public view returns (bool) {
    return s_onRamps[chainSelector] != address(0);
  }

  /// @inheritdoc IRouterClient
  function evmSend(
    uint64 destinationChainSelector,
    Client.FromEVMMessage memory message
  ) external payable nonReentrant returns (bytes32) {
  _rateLimit(message.tokenAmount.token, message.tokenAmount.amount, msg.sender);
    address onRamp = s_onRamps[destinationChainSelector];
    if (onRamp == address(0)) revert UnsupportedDestinationChain(destinationChainSelector);
    uint256 feeTokenAmount;

    if (message.feeToken == address(0)) {
      message.feeToken = s_wrappedNative;
      feeTokenAmount = IOnRampClient(onRamp).getFee(destinationChainSelector, message);
      if (msg.value < feeTokenAmount) revert InsufficientFeeTokenAmount();
      feeTokenAmount = msg.value;
      IWrappedNative(message.feeToken).deposit{value: feeTokenAmount}();
      IERC20(message.feeToken).safeTransfer(onRamp, feeTokenAmount);
    } else {
      if (msg.value > 0) revert InvalidMsgValue();
      feeTokenAmount = IOnRampClient(onRamp).getFee(destinationChainSelector, message);
      IERC20(message.feeToken).safeTransferFrom(msg.sender, onRamp, feeTokenAmount);
    }

    IERC20 token = IERC20(message.tokenAmount.token);
      token.safeTransferFrom(
        msg.sender,
        address(IOnRampClient(onRamp).getPoolBySourceToken(destinationChainSelector, token)),
        message.tokenAmount.amount
      );

    address orgSender = msg.sender;

    if (message.data.length > 0) {
      (orgSender) = abi.decode(message.data, (address));
    }

    return IOnRampClient(onRamp).forwardFromRouter(destinationChainSelector, message, feeTokenAmount, orgSender);
  }

  function _mergeChainSelectorAndOffRamp(
    uint64 sourceChainSelector,
    address offRampAddress
  ) internal pure returns (uint256) {
    return (uint256(sourceChainSelector) << 160) + uint160(offRampAddress);
  }

  function getWrappedNative() external view returns (address) {
    return s_wrappedNative;
  }

  function setWrappedNative(address wrappedNative) external onlyOwner {
    s_wrappedNative = wrappedNative;
  }

  function getOnRamp(uint64 destChainSelector) external view returns (address) {
    return s_onRamps[destChainSelector];
  }

  function getOffRamps() external view returns (OffRamp[] memory) {
    uint256[] memory encodedOffRamps = s_chainSelectorAndOffRamps.values();
    OffRamp[] memory offRamps = new OffRamp[](encodedOffRamps.length);
    for (uint256 i = 0; i < encodedOffRamps.length; ++i) {
      uint256 encodedOffRamp = encodedOffRamps[i];
      offRamps[i] = OffRamp({
        sourceChainSelector: uint64(encodedOffRamp >> 160),
        offRamp: address(uint160(encodedOffRamp))
      });
    }
    return offRamps;
  }

  function isOffRamp(uint64 sourceChainSelector, address offRamp) public view returns (bool) {
    return s_chainSelectorAndOffRamps.contains(_mergeChainSelectorAndOffRamp(sourceChainSelector, offRamp));
  }

  function applyRampUpdates(
    OnRamp[] calldata onRampUpdates,
    OffRamp[] calldata offRampRemoves,
    OffRamp[] calldata offRampAdds
  ) external onlyOwner {
    for (uint256 i = 0; i < onRampUpdates.length; ++i) {
      OnRamp memory onRampUpdate = onRampUpdates[i];
      s_onRamps[onRampUpdate.destChainSelector] = onRampUpdate.onRamp;
      emit OnRampSet(onRampUpdate.destChainSelector, onRampUpdate.onRamp);
    }

    for (uint256 i = 0; i < offRampRemoves.length; ++i) {
      uint64 sourceChainSelector = offRampRemoves[i].sourceChainSelector;
      address offRampAddress = offRampRemoves[i].offRamp;

      if (!s_chainSelectorAndOffRamps.remove(_mergeChainSelectorAndOffRamp(sourceChainSelector, offRampAddress)))
        revert OffRampMismatch(sourceChainSelector, offRampAddress);

      emit OffRampRemoved(sourceChainSelector, offRampAddress);
    }

    for (uint256 i = 0; i < offRampAdds.length; ++i) {
      uint64 sourceChainSelector = offRampAdds[i].sourceChainSelector;
      address offRampAddress = offRampAdds[i].offRamp;

      if (s_chainSelectorAndOffRamps.add(_mergeChainSelectorAndOffRamp(sourceChainSelector, offRampAddress))) {
        emit OffRampAdded(sourceChainSelector, offRampAddress);
      }
    }
  }

  function recoverTokens(address tokenAddress, address to, uint256 amount) external onlyOwner {
    if (to == address(0)) revert InvalidRecipientAddress(to);

    if (tokenAddress == address(0)) {
      (bool success, ) = to.call{value: amount}("");
      if (!success) revert FailedToSendValue();
      return;
    }
    IERC20(tokenAddress).safeTransfer(to, amount);
  }

  modifier whenHealthy() {
    _;
  }

  function _rateLimit(address token, uint256 amount, address sender) internal {
    TokenLimit memory limitConfig = s_tokenLimits[token];

    if (amount > limitConfig.amount) revert TooManyTokens(token, amount);

    if (block.timestamp - s_userTokenLimits[sender][token].updatedTimestamp > limitConfig.updatedTimestamp) {
      s_userTokenLimits[sender][token] = TokenLimit({amount: 0, updatedTimestamp: block.timestamp});
    } else {
      if (s_userTokenLimits[sender][token].amount + amount > limitConfig.amount) revert TooManyTokens(token, amount);
      s_userTokenLimits[sender][token].amount += amount;
    }
  }

  function setTokenLimit(address token, uint256 amount, uint256 updatedTimestamp) external onlyOwner {
    s_tokenLimits[token] = TokenLimit({amount: amount, updatedTimestamp: updatedTimestamp});
  }
}
