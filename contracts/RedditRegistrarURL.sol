pragma solidity ^0.4.8;

import "../installed_contracts/oraclize/contracts/usingOraclize.sol";
import '../installed_contracts/zeppelin/contracts/ownership/Ownable.sol';

contract RegistrarI {
  function register(string _proof, address _addr) payable returns(bytes32 oracleId);
  function getCost() constant returns (uint cost);
  //Below functions used for testing and internally
  function _register(bytes32 oracleId, address expectedAddress, string proof);
  function _callback(bytes32 _id, string _result);
  function _clearOracleId(bytes32 oracleId);
}

contract RegistryI {
  function update(string _name, address _addr, string _proof);
  function error(bytes32 _id, address _addr, string _result, string _message);
}

contract RedditRegistrarURL is RegistrarI, Ownable, usingOraclize {

  event OracleQueryReceived(string _result, bytes32 _id);
  event OracleQuerySent(string _url, bytes32 _id);
  event AddressMismatch(address _oracleAddr, address _addr);
  event BadOracleResult(string _message, string _result, bytes32 _id);

  mapping (bytes32 => address) oracleExpectedAddress;
  mapping (bytes32 => string) oracleProof;
  mapping (bytes32 => bool) oracleCallbackComplete;

  uint oraclizeGasLimit = 280000;

  //json(https://www.reddit.com/r/ethereumproofs/comments/66xvua.json).0.data.children.0.data.[author,title]
  string queryUrlPrepend = 'json(https://www.reddit.com/r/ethereumproofs/comments/';
  string queryUrlAppend = '.json).0.data.children.0.data.[author,title]';

  RegistryI registry;

  modifier onlyOraclizeOrOwner() {
    if ((msg.sender != owner) && (msg.sender != oraclize_cbAddress())) {
      throw;
    }
    _;
  }

  function RedditRegistrarURL() {
    registry = RegistryI(msg.sender);
  }

  function getCost() onlyOwner public constant returns(uint cost) {
    return oraclize_getPrice("URL", oraclizeGasLimit);
  }

  function __callback(bytes32 _id, string _result) {
    //Check basic error conditions (throw on error)
    if (msg.sender != oraclize_cbAddress()) throw;
    if (oracleCallbackComplete[_id]) throw;
    _callback(_id, _result);
  }

  function _callback(bytes32 _id, string _result) onlyOraclizeOrOwner {

    //Record callback received
    oracleCallbackComplete[_id] = true;
    OracleQueryReceived(_result, _id);

    //Check contract specific error conditions (set event and return on error)
    var (success, redditName, redditAddrString) = parseResult(_result);
    if (!success) {
      BadOracleResult("Incorrect length data returned from Oracle", _result, _id);
      registry.error(_id, oracleExpectedAddress[_id], _result, "Unable to parse Oraclize response");
    } else {
      //Check validity of claim to address
      address redditAddr = parseAddr(redditAddrString);
      if (oracleExpectedAddress[_id] != redditAddr) {
        AddressMismatch(redditAddr, oracleExpectedAddress[_id]);
        registry.error(_id, oracleExpectedAddress[_id], _result, "Address mismatch");
      } else {
        //We can now update our registry!!!
        registry.update(redditName, redditAddr, oracleProof[_id]);
      }
    }

  }

  function register(string _proof, address _addr) payable onlyOwner returns(bytes32 oracleId) {

    string memory oracleQuery = strConcat(queryUrlPrepend, _proof, queryUrlAppend);
    oracleId = oraclize_query("URL", oracleQuery, oraclizeGasLimit);
    OracleQuerySent(oracleQuery, oracleId);
    _register(oracleId, _addr, _proof);
    return oracleId;

  }

  function _register(bytes32 oracleId, address expectedAddress, string proof) onlyOwner {
    oracleExpectedAddress[oracleId] = expectedAddress;
    oracleProof[oracleId] = proof;
  }

  function _clearOracleId(bytes32 oracleId) onlyOwner {
    oracleExpectedAddress[oracleId] = 0x0;
    oracleProof[oracleId] = "";
    oracleCallbackComplete[oracleId] = false;
  }

  function parseResult(string _input) internal returns (bool success, string name, string addr) {
    bytes memory inputBytes = bytes(_input);
    //Zero length input
    if (inputBytes.length == 0) {
      //below amounts to false, "", ""
      return (success, name, addr);
    }
    //Non array input
    if (inputBytes[0] != '[' || inputBytes[inputBytes.length - 1] != ']') {
      return (success, name, addr);
    }
    //Sensible length (current reddit username is max. 20 chars, ethereum address is 42 chars)
    if (inputBytes.length > 80) {
      return (success, name, addr);
    }
    //Need to loop twice:
    //Outer loop to determine length of token
    //Inner loop to initialize token with correct length and populate
    uint tokensFound = 0;
    bytes memory bytesBuffer;
    uint bytesLength = 0;
    uint bytesStart;
    uint inputPos = 0;
    bytes1 c;
    bool reading = false;
    //We know first and last bytes are square brackets
    for (inputPos = 1; inputPos < inputBytes.length - 1; inputPos++) {
      //Ignore escaped speech marks
      if ((inputBytes[inputPos] == '"') && (inputBytes[inputPos - 1] != '\\')) {
        if (!reading) {
          bytesStart = inputPos + 1;
        }
        if (reading) {
          bytesBuffer = new bytes(bytesLength);
          for (uint i = bytesStart; i < inputPos; i++) {
            bytesBuffer[i - bytesStart] = inputBytes[i];
          }
          if (tokensFound == 0) {
            name = string(bytesBuffer);
          } else {
            //Otherwise parseAddr will throw
            if (bytesLength != 42) {
              return (success, name, addr);
            }
            addr = string(bytesBuffer);
          }
          bytesLength = 0;
          tokensFound++;
        }
        reading = !reading;
        continue;
      }
      if (reading) {
        bytesLength++;
      }
    }
    if (tokensFound != 2) {
      return (success, name, addr);
    }
    success = true;
    return (success, name, addr);
  }

}
