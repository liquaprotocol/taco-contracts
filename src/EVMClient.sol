// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouterClient} from "./interfaces/IRouterClient.sol";

import {Client} from "./libraries/Client.sol";
import {Receiver} from "./Receiver.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract EVMClient is Receiver, Ownable {
  error InvalidChain(uint64 chainSelector);

  event MessageSent(bytes32 messageId);
  event MessageReceived(bytes32 messageId);

  // fee feeToken
  IERC20 public s_feeToken;

  constructor(IRouterClient router, address feeToken) Receiver(address(router)) Ownable(msg.sender) {
    if (feeToken != address(0)) {
      s_feeToken = IERC20(feeToken);
      s_feeToken.approve(address(router), type(uint256).max);
    }
    
  }

  function getFee(
    uint64 destChainSelector,
    address receiver,
    Client.EVMTokenAmount memory tokenAmount
  ) external view returns (uint256) {
    Client.FromEVMMessage memory message = Client.FromEVMMessage({
      receiver: receiver,
      data: abi.encode(msg.sender),
      tokenAmount: tokenAmount,
      feeToken: address(s_feeToken)
    });
    return IRouterClient(i_ccipRouter).getFee(destChainSelector, message);
  }

  // @notice user sends tokens to a receiver
  // Approvals can be optimized with a whitelist of tokens and inf approvals if desired.
  function sendToken(
    uint64 destChainSelector,
    address receiver,
    Client.EVMTokenAmount memory tokenAmount
  ) external payable returns (bytes32) {
    // IERC20(tokenAmount.token).transferFrom(msg.sender, address(this), tokenAmount.amount);
    // IERC20(tokenAmount.token).approve(i_ccipRouter, tokenAmount.amount);
    // Client.FromEVMMessage memory message = Client.FromEVMMessage({
    //   receiver: receiver,
    //   data: abi.encode(msg.sender),
    //   tokenAmount: tokenAmount,
    //   feeToken: address(s_feeToken)
    // });
    // bytes32 messageId = IRouterClient(i_ccipRouter).evmSend{
    //   value: msg.value
    // }(destChainSelector, message);
    // emit MessageSent(messageId);

    // return messageId;
  }

  function setRouter(address router) external onlyOwner {
    _setRouter(router);
  }
}
