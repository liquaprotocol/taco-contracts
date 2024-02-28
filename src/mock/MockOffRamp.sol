// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "../interfaces/IOffRamp.sol";
import "../interfaces/IPool.sol";

import {Client} from "../libraries/Client.sol";


contract OffRamp {

    address sender;

    constructor()  {}

    function executeSingleMessage(
        Client.EVM2EVMMessage memory message,
        bytes memory offchainTokenData
    ) external view {
        
    }

  
}
