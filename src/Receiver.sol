// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {Client} from "./libraries/Client.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract Receiver is IERC165 {
  error InvalidRouter(address router);
  address internal i_ccipRouter;

  constructor(address router) {
    if (router == address(0)) revert InvalidRouter(address(0));
    i_ccipRouter = router;
  }

  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return  interfaceId == type(IERC165).interfaceId;
  }

  function getRouter() public view returns (address) {
    return address(i_ccipRouter);
  }

  function _setRouter(address router) internal {
    i_ccipRouter = router;
  }

  modifier onlyRouter() {
    if (msg.sender != address(i_ccipRouter)) revert InvalidRouter(msg.sender);
    _;
  }
}
