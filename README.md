![taco.png](https://github.com/liquaprotocol/taco-contracts/blob/main/img/taco.png)

<p align="center">
<a href="https://www.liqua.io/">
  <img src='https://img.shields.io/github/languages/code-size/liquaprotocol/taco-contracts'>
</a>
<a href="https://www.liqua.io/">
  <img src='https://img.shields.io/github/languages/top/liquaprotocol/taco-contracts'>
</a>
</p>

# Taco Cross-Chain Bridge

Welcome to Taco Cross-Chain Bridge, an open-source project designed to facilitate seamless asset transfers between different blockchain networks. As the blockchain ecosystem continues to expand, interoperability between networks has become increasingly important. Taco Cross-Chain Bridge aims to address this need by providing a reliable and secure platform for users to transfer assets, such as tokens or cryptocurrencies, across different blockchains.

Our cross-chain bridge leverages innovative technology to ensure trustless and efficient asset transfers. Through smart contracts and oracles, Taco Bridge enables users to lock assets on one blockchain and mint corresponding tokens on another, allowing for seamless interoperability between disparate networks. Additionally, Taco Bridge prioritizes security and decentralization, utilizing robust cryptographic techniques to safeguard assets and minimize the risk of unauthorized access or manipulation.

Whether you're a developer looking to integrate cross-chain functionality into your application or a user seeking to transfer assets between blockchains, Taco Cross-Chain Bridge provides a reliable and user-friendly solution. We welcome contributions from the community to help improve and expand the functionality of Taco Bridge, and invite you to join us on GitHub to collaborate and contribute to the future of cross-chain interoperability.

> **Warning**
>
> _This repository contains experimental code. It is available as a technology preview and its functionality is subject to change. Breaking changes may be introduced at any point while it is in preview._

--- 

## 📦 Install


###  Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

Foundry consists of:
-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

Documentation: https://book.getfoundry.sh/

### Getting Started

1. Install Liburaries

```shell
$ forge install foundry-rs/forge-std
$ forge install openzeppelin/openzeppelin-contracts
```

and

```
npm install
```

2. Compile Contracts

```
forge build
```

3. Run Tests
```shell
$ forge test
```

4. Format Code
```shell
$ forge fmt
```

5. Take Gas Snapshots
```shell
$ forge snapshot
```

6. Deploy Contracts
```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

7. Use Anvil
```shell
$ anvil
```

8. Cast
```shell
$ cast <subcommand>
```

9. Help
```shell
$ forge --help
$ anvil --help
$ cast --help
```

## 📃 Deployments



## 📜 License

**TBC**



