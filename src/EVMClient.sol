// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouterClient} from "./interfaces/IRouterClient.sol";

import {Client} from "./libraries/Client.sol";
import {Receiver} from "./Receiver.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract EVMClient is Receiver, Ownable {
  error InvalidConfig();
  error InvalidChain(uint64 chainSelector);

  event MessageSent(bytes32 messageId);
  event MessageReceived(bytes32 messageId);

  // fee feeToken
  IERC20 public s_feeToken;
  mapping(uint64 destChainSelector => bytes extraArgsBytes) public s_chains;

  constructor(IRouterClient router, address feeToken) Receiver(address(router)) Ownable(msg.sender) {
    if (feeToken != address(0)) {
      s_feeToken = IERC20(feeToken);
      s_feeToken.approve(address(router), type(uint256).max);
    }
    
  }

  function enableChain(uint64 chainSelector, bytes memory extraArgs) external onlyOwner {
    s_chains[chainSelector] = extraArgs;
  }

  function disableChain(uint64 chainSelector) external onlyOwner {
    delete s_chains[chainSelector];
  }

  function evmReceive(
    Client.ToEVMMessage calldata message
  ) external virtual override onlyRouter validChain(message.sourceChainSelector) {
    emit MessageReceived(message.messageId);

  }

  // @notice user sends tokens to a receiver
  // Approvals can be optimized with a whitelist of tokens and inf approvals if desired.
  function sendToken(
    uint64 destChainSelector,
    address receiver,
    Client.EVMTokenAmount memory tokenAmount
  ) external validChain(destChainSelector) returns (bytes32) {
    IERC20(tokenAmount.token).transferFrom(msg.sender, address(this), tokenAmount.amount);
    IERC20(tokenAmount.token).approve(i_ccipRouter, tokenAmount.amount);
    Client.FromEVMMessage memory message = Client.FromEVMMessage({
      receiver: receiver,
      data: abi.encode(msg.sender),
      tokenAmount: tokenAmount,
      feeToken: address(s_feeToken)
    });
    bytes32 messageId = IRouterClient(i_ccipRouter).evmSend(destChainSelector, message);
    emit MessageSent(messageId);

    return messageId;
  }

  modifier validChain(uint64 chainSelector) {
    if (s_chains[chainSelector].length == 0) revert InvalidChain(chainSelector);
    _;
  }
}
