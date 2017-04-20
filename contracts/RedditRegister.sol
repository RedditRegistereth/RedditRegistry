pragma solidity ^0.4.8;

import "../installed_contracts/oraclize/contracts/usingOraclize.sol";

contract RedditRegister is usingOraclize {

  event NameAddressRegistered(string _name, address _addr);
  event AddressOracleReceived(string _result, bytes32 _id);
  event AddressOracleSent(string _url, bytes32 _id);
  event NameOracleReceived(string _result, bytes32 _id);
  event NameOracleSent(string _url, bytes32 _id);
  event AddressMismatch(address _actual, address _expected);
  event InsufficientFunds(uint _funds, uint _cost);
  event BadOracleResult(string _message, bytes32 _id);

  enum OracleType { NAME, ADDR }

  mapping (address => string) addrToName;
  mapping (string => address) nameToAddr;

  mapping (bytes32 => OracleType) oracleCallbackType;
  mapping (bytes32 => address) oracleExpectedAddress;
  mapping (bytes32 => string) oracleName;

  mapping (bytes32 => bytes32) addrToNameCallbackId;
  mapping (bytes32 => bytes32) nameToAddrCallbackId;

  mapping (bytes32 => bool) addrOracleCallbackComplete;
  mapping (bytes32 => bool) nameOracleCallbackComplete;

  address owner;

  function RedditRegister() {
    owner = msg.sender;
  }

  function lookupAddr(address _addr) public constant returns(string name) {
    return addrToName[_addr];
  }

  function lookupName(string _name) public constant returns(address addr) {
    return nameToAddr[_name];
  }

  function __callback(bytes32 _id, string _result) {

    if (msg.sender != oraclize_cbAddress()) throw;
    bytes memory resultBytes = bytes(_result);
    uint resultLength = resultBytes.length;
    if (resultLength == 0) {
      BadOracleResult("Empty result returned from Oracle", _id);
    } else if (oracleCallbackType[_id] == OracleType.ADDR) {
      AddressOracleReceived(_result, _id);
      address oracleAddr = parseAddr(_result);
      if (oracleExpectedAddress[_id] == oracleAddr) {
        addrOracleCallbackComplete[_id] = true;
        bytes32 nameId = addrToNameCallbackId[_id];
        if (nameOracleCallbackComplete[nameId]) {
          update(oracleName[nameId], oracleAddr);
        }
      } else {
        AddressMismatch(oracleExpectedAddress[_id], oracleAddr);
      }
    } else if (oracleCallbackType[_id] == OracleType.NAME) {
      NameOracleReceived(_result, _id);
      nameOracleCallbackComplete[_id] = true;
      oracleName[_id] = _result;
      bytes32 addrId = nameToAddrCallbackId[_id];
      if (addrOracleCallbackComplete[addrId]) {
        update(_result, oracleExpectedAddress[addrId]);
      }
    } else {
      throw;
    }

  }

  function register(string _hash, address _addr) public payable returns(bool success) {
      //_addr not strictly needed - but we use it to do an upfront check to avoid wasted oracle queries
      if (msg.sender != _addr) {
        AddressMismatch(msg.sender, _addr);
        return false;
      }
      uint oraclePrice = oraclize_getPrice("URL");
      if ((2 * oraclePrice) > this.balance) {
        InsufficientFunds(this.balance, 2 * oraclePrice);
        return false;
      }
      string memory addrOracleQuery = strConcat('json(https://www.reddit.com/r/ethereumproofs/comments/', _hash, '.json).0.data.children.0.data.title');
      string memory nameOracleQuery = strConcat('json(https://www.reddit.com/r/ethereumproofs/comments/', _hash, '.json).0.data.children.0.data.author');
      bytes32 addrOracleId = oraclize_query("URL", addrOracleQuery);
      AddressOracleSent(addrOracleQuery, addrOracleId);
      bytes32 nameOracleId = oraclize_query("URL", nameOracleQuery);
      NameOracleSent(nameOracleQuery, nameOracleId);
      oracleCallbackType[addrOracleId] = OracleType.ADDR;
      oracleCallbackType[nameOracleId] = OracleType.NAME;
      addrToNameCallbackId[addrOracleId] = nameOracleId;
      nameToAddrCallbackId[nameOracleId] = addrOracleId;
      oracleExpectedAddress[addrOracleId] = msg.sender;
      return true;
  }

  function update(string _name, address _addr) internal returns(bool success) {
    addrToName[_addr] = _name;
    nameToAddr[_name] = _addr;
    NameAddressRegistered(_name, _addr);
    return true;
  }

}
