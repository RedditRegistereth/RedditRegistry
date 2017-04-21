pragma solidity ^0.4.8;

import "../installed_contracts/oraclize/contracts/usingOraclize.sol";

contract RedditRegister is usingOraclize {

  event NameAddressHashRegistered(string _name, address _addr, string _hash);
  event OracleQueryReceived(string _result, bytes32 _id);
  event OracleQuerySent(string _url, bytes32 _id);
  event AddressMismatch(address _actual, address _expected);
  event InsufficientFunds(uint _funds, uint _cost);
  event BadOracleResult(string _message, string _result, bytes32 _id);

  enum OracleType { NAME, ADDR }

  mapping (address => string) addrToName;
  mapping (string => address) nameToAddr;
  mapping (address => string) addrToHash;
  mapping (bytes32 => address) oracleExpectedAddress;
  mapping (bytes32 => string) oracleHash;
  mapping (bytes32 => bool) oracleCallbackComplete;

  string queryUrlPrepend = 'json(https://www.reddit.com/r/ethereumproofs/comments/';
  string queryUrlAppend = '.json).0.data.children.0.data.[author,title]';

  address owner;

  function RedditRegister() {
    owner = msg.sender;
  }

  function lookupAddr(address _addr) public constant returns(string name) {
    return addrToName[_addr];
  }

  function lookupHash(address _addr) public constant returns(string hash) {
    return addrToHash[_addr];
  }

  function lookupName(string _name) public constant returns(address addr) {
    return nameToAddr[_name];
  }

  function __callback(bytes32 _id, string _result) {
    //Check basic error conditions (throw on error)
    if (msg.sender != oraclize_cbAddress()) throw;
    if (oracleCallbackComplete[_id]) throw;
    _callback(_id, _result);
  }

  function _callback(bytes32 _id, string _result) internal {

    //Record callback received
    oracleCallbackComplete[_id] = true;
    OracleQueryReceived(_result, _id);

    //Check contract specific error conditions (set event and return on error)
    var (success, redditName, redditAddrString) = parseResult(_result);
    if (!success) {
      BadOracleResult("Incorrect length data returned from Oracle", _result, _id);
      return;
    }

    //Check validity of claim to address
    address redditAddr = parseAddr(redditAddrString);
    if (oracleExpectedAddress[_id] != redditAddr) {
      AddressMismatch(oracleExpectedAddress[_id], redditAddr);
      return;
    }

    //We can now update our registry!!!
    update(redditName, redditAddr, oracleHash[_id]);

  }

  function register(string _hash, address _addr) public payable returns(bytes32 oracleId) {

      //_addr not strictly needed - but we use it to do an upfront check to avoid wasted oracle queries
      if (msg.sender != _addr) {
        AddressMismatch(msg.sender, _addr);
      }

      uint oraclePrice = oraclize_getPrice("URL");
      if (oraclePrice > this.balance) {
        InsufficientFunds(this.balance, oraclePrice);
      }

      string memory oracleQuery = strConcat(queryUrlPrepend, _hash, queryUrlAppend);
      oracleId = oraclize_query("URL", oracleQuery);
      OracleQuerySent(oracleQuery, oracleId);
      oracleExpectedAddress[oracleId] = msg.sender;
      oracleHash[oracleId] = _hash;

  }

  function update(string _name, address _addr, string _hash) internal returns(bool success) {
    addrToName[_addr] = _name;
    nameToAddr[_name] = _addr;
    addrToHash[_addr] = _hash;
    NameAddressHashRegistered(_name, _addr, _hash);
    return true;
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
