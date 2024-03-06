// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPool} from "./interfaces/IPool.sol";
import {IOnRampClient} from "./interfaces/IOnRampClient.sol";
import {Client} from "./libraries/Client.sol";
import {EnumerableMapAddresses} from "./libraries/EnumerableMapAddresses.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract OnRamp is IOnRampClient, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableMapAddresses for EnumerableMapAddresses.AddressToAddressMap;

    /// @dev The current nonce per sender.
    /// The offramp has a corresponding s_senderNonce mapping to ensure messages
    /// are executed in the same order they are sent.
    mapping(address sender => uint64 nonce) internal s_senderNonce;

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

    constructor(Client.PoolUpdate[] memory tokensAndPools) Ownable() {
        _applyPoolUpdates(new Client.PoolUpdate[](0), tokensAndPools);
    }

    function getFee(
        uint64,
        Client.FromEVMMessage memory
    ) external pure override returns (uint256 fee) {
        return 0;
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
}
