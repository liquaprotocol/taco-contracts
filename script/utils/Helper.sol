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
            router: 0x9e50161161d09544c07B0219a11fe4B06dB093b6,
            weth: 0xb9f56e3659f927C54220a5E6Ded46162dD826A08,
            evmClient: 0xc968f4aB5eF11FF6042A98c528Cc3F6933255305,
            onRamp: 0x88808876AEDE71E9362b87F42A20b791BB5a3075,
            offRamp: 0xc0d3Da510eFeFf1e2E7c081D412C6B1933F14EC8,
            wethTokenPool: 0x00D60ea27643c4592843aC9a9ECd51b5e29Ab41c,
            priceFeed: 0x9C47ac009fd21d61c2EcC40eD29fcF8E6f228B4d
        });

        networkInfo[167008] = TacoNetworkInfo({
            chainId: 167008,
            router: 0x70aFc3C68fa69E44D09EdBbDa9893224C9290AEE,
            weth: 0x3cFd763b341DfCC2B0C75bAd2120e0ad230B9eF3,
            evmClient: 0x1E306C22510b67a7B2F234af411567d08d502A07,
            onRamp: 0xFC867f9dB473dD14198dfDAdF1bCBbc44365Ced9,
            offRamp: 0x7ec1A00BBB02cb03A0dfe03F54A3B08204e69487,
            wethTokenPool: 0x7203587fA7b3eD1e4D0098fE2D8a93298cB0c9Bd,
            priceFeed: 0xca4dF7B3fCd903315b2937422E80144181a90299
        });
        networkInfo[5003] = TacoNetworkInfo({
            chainId: 5003,
            router: 0x05BD03465d4331384295D7Ee59476CE323bE56de,
            weth: 0x7ec1A00BBB02cb03A0dfe03F54A3B08204e69487,
            evmClient: 0x528B788e277d5dd27c164Ef40dc2748495479b4E,
            onRamp: 0x03A7b1FbE69E9CdDF34f90BD3D89F6340ea1E8e3,
            offRamp: 0xD8F7e52d4c7673d09aA0535d26FFc236bc82578d,
            wethTokenPool: 0xBe663683c7D1bfb2D3904fd6889CB4A9F351CA03,
            priceFeed: 0x24CDA3A0DFA705b6b4A8eC9A29e48369f9BB42Ff
        });
    }
}