// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Helper {
    // Supported Networks
    enum SupportedNetworks {
        ETHEREUM_SEPOLIA,
        KATLA_TAIKO,
        MANTLE_SEPOLIA
    }

    mapping(SupportedNetworks enumValue => string humanReadableName)
        public networks;

    enum PayFeesIn {
        Native
    }

    // Chain IDs
    uint64 constant chainIdEthereumSepolia = 11155111;
    uint64 constant chainIdKatlaTaiko = 167008;
    uint64 constant chainIdMantleSepolia = 5003;

    // EVMClient Addresses
    address constant routerEthereumSepolia = 0x959E4F354A38FDE1De3Fd6E5a8beB463Da6C1d47;
    address constant routerKatlaTaiko = 0x0e397a9f1c355cCaeed071b9fDa3FA6B761a2E38;
    address constant routerMantleSepolia = 0xAd7E4a6dfFFa8c534DbB0A8899D2Bb4c38559F9B;

    // OnRamp Addresses
    address constant onRampEthereumSepolia = 0x7203587fA7b3eD1e4D0098fE2D8a93298cB0c9Bd;
    address constant onRampKatlaTaiko = 0x4AA9a0419464f1477aF0A9cf09286aBeb7E10Dec;
    address constant onRampMantleSepolia = 0x6B549ea5924486d0a35C891bB0D0c8bd19bb6b86;

    // OffRamp Addresses
    address constant offRampEthereumSepolia = 0xd938fa2AC448Ef5B577EDdFfB9e0bEd8D7019568;
    address constant offRampKatlaTaiko = 0x0C0B89F038eC1470A4FB7d25Bf69083Ad4Fbde3c;
    address constant offRampMantleSepolia = 0xB55511C9A35343825f971574Ed4E2ea6224Ed891;




    // Weth Addresses
    address constant wethEthereumSepolia = 0xb9f56e3659f927C54220a5E6Ded46162dD826A08;
    address constant wethKatlaTaiko = 0x3cFd763b341DfCC2B0C75bAd2120e0ad230B9eF3;
    address constant wethMantleSepolia = 0x0C0B89F038eC1470A4FB7d25Bf69083Ad4Fbde3c;

    // TODO: USDC Addresses
    address constant usdcEthereumSepolia = 0x0000000000000000000000000000000000000000;
    address constant usdcKatlaTaiko = 0x0000000000000000000000000000000000000000;
    address constant usdcMantleSepolia = 0x0000000000000000000000000000000000000000;


    // Weth Token Pool Addresses
    address constant wethTokenPoolEthereumSepolia = 0x0000000000000000000000000000000000000000;
    address constant wethTokenPoolKatlaTaiko = 0x0000000000000000000000000000000000000000;
    address constant wethTokenPoolMantleSepolia = 0x0000000000000000000000000000000000000000;

    // Usdc Token Pool Addresses
    address constant usdcTokenPoolEthereumSepolia = 0x0000000000000000000000000000000000000000;
    address constant usdcTokenPoolKatlaTaiko = 0x0000000000000000000000000000000000000000;
    address constant usdcTokenPoolMantleSepolia = 0x0000000000000000000000000000000000000000;

    constructor() {
        networks[SupportedNetworks.ETHEREUM_SEPOLIA] = "Ethereum Sepolia";
        networks[SupportedNetworks.KATLA_TAIKO] = "Katla Taiko";
        networks[SupportedNetworks.MANTLE_SEPOLIA] = "Mantle Sepolia";
    }

    function getDummyTokensFromNetwork(
        SupportedNetworks network
    ) internal pure returns (address token1, address token2) {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (wethEthereumSepolia, usdcEthereumSepolia);
        } else if (network == SupportedNetworks.KATLA_TAIKO) {
            return (wethKatlaTaiko, usdcKatlaTaiko);
        } else if (network == SupportedNetworks.MANTLE_SEPOLIA) {
            return (wethMantleSepolia, usdcMantleSepolia);
        }
    }

    // function getConfigFromNetwork(
    //     SupportedNetworks network
    // )
    //     internal
    //     pure
    //     returns (
    //         address router,
    //         address linkToken,
    //         address wrappedNative,
    //         uint64 chainId
    //     )
    // {
    //     if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
    //         return (
    //             routerEthereumSepolia,
    //             linkEthereumSepolia,
    //             wethEthereumSepolia,
    //             chainIdEthereumSepolia
    //         );
    //     }
    // }
}
