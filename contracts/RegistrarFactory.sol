pragma solidity ^0.4.8;

import "./RedditRegistrarURL.sol";

library RegistrarFactory {
  function newURLRegistrar() returns (RegistrarI) {
    return new RedditRegistrarURL();
  }
}
