// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Helper {
    struct TacoNetworkInfo {
        uint64 chainId;
        address router;
        address weth;
        address evmClient;
        address onRamp;
        address offRamp;
        address wethTokenPool;
        address priceFeed;
    }

    mapping(uint64 => TacoNetworkInfo) public networkInfo;

    constructor() {
        // sepoila
        networkInfo[11155111] = TacoNetworkInfo({
            chainId: 11155111,
            weth: 0xb9f56e3659f927C54220a5E6Ded46162dD826A08,
            priceFeed: 0x8908E4562c474c57d275E55c35b23a9d22495E26,
            router: 0xf0795CDf440E64abd51b78a861B37C8BA97D44AA,
            evmClient: 0xDbdb93454f2BE9a9acC64E9DfF9dB66e56F4Eee8,
            wethTokenPool: 0x3D6A6D8Bf41B8A3E602D7a5b14915c066Ec110Cf,
            onRamp: 0x9027522317611d5c5DeE26A01a8ad6E6855c5947,
            offRamp: 0x515e18909be53Fd05862216696e3016Dc53B44E6
        });

        networkInfo[167008] = TacoNetworkInfo({
            chainId: 167008,
            weth: 0x3cFd763b341DfCC2B0C75bAd2120e0ad230B9eF3,
            priceFeed: 0x13efcfAc8b17992Bcd2C7D4B64A9864797d6294F,
            router: 0x5Ed2CD6e747E3e0a81623Fa7a8DabF5fA9557661,
            evmClient: 0xdd3aAe0E5dfd45Afad690a25AD7c17496c673A40,
            wethTokenPool: 0xa40F47bF1D7061E4c46a4502a5507B4350bbb808,
            onRamp: 0x7759D6d2e3FB9A6984F28041cB65FC8C841FCd1A,
            offRamp: 0x265134F5b931D94c35C83c8209847a35C924547E
        });
        networkInfo[5003] = TacoNetworkInfo({
            chainId: 5003,
            weth: 0x7ec1A00BBB02cb03A0dfe03F54A3B08204e69487,
            priceFeed: 0x5Aa2Be71aaa1FA38FBf2862A360548b433e87159,
            router: 0xe71a3D0C565f51EB86c96aA3Fd74330d979404a4,
            evmClient: 0x13efcfAc8b17992Bcd2C7D4B64A9864797d6294F,
            wethTokenPool: 0x5Ed2CD6e747E3e0a81623Fa7a8DabF5fA9557661,
            onRamp: 0xdd3aAe0E5dfd45Afad690a25AD7c17496c673A40,
            offRamp: 0xa40F47bF1D7061E4c46a4502a5507B4350bbb808
        });

        networkInfo[42161] = TacoNetworkInfo({
            chainId: 42161,
            weth: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            priceFeed: address(0),
            router: address(0),
            evmClient: address(0),
            wethTokenPool: address(0),
            onRamp: address(0),
            offRamp: address(0)
        });
        networkInfo[5000] = TacoNetworkInfo({
            chainId: 5000,
            weth: 0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111,
            priceFeed: 0xD7b639f5a3811519007c9e389A479f90B87a06D9,
            router: 0x260E2F070026e81d65548a15acFd6Fc9FDDE1C0a,
            evmClient: 0x663D68e8ab26d70044e43B6210d48ecC02654baE,
            wethTokenPool: 0xA5e223511edf8286214b52F2E0Bd4E5Ce925fb31,
            onRamp: 0x4B789C88dcD5D2BB449f09300785bDEFc8E14608,
            offRamp: 0xd2Fe290a4c75D9EB3bfFA83c4fe3cDd5ddbD88d7
        });
        networkInfo[10] = TacoNetworkInfo({
            chainId: 10,
            weth: 0x4200000000000000000000000000000000000006,
            priceFeed: 0x663D68e8ab26d70044e43B6210d48ecC02654baE,
            router: 0xA5e223511edf8286214b52F2E0Bd4E5Ce925fb31,
            evmClient: 0x4B789C88dcD5D2BB449f09300785bDEFc8E14608,
            wethTokenPool: 0xd2Fe290a4c75D9EB3bfFA83c4fe3cDd5ddbD88d7,
            onRamp: 0xbcF8E08C62Ed1f8E965054DB492D44aedac9A49B,
            offRamp: 0x50c2b297EA06fE633926Db5FBc724Fce823Aef06
        });
    }
}
