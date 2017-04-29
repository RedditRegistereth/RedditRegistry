pragma solidity ^0.4.8;

import "../installed_contracts/oraclize/contracts/usingOraclize.sol";
import '../installed_contracts/zeppelin/contracts/ownership/Ownable.sol';

import "./RedditRegistrarURL.sol";
import "./RegistrarFactory.sol";

contract RedditRegistry is RegistryI, Ownable {

  event RegistrationSent(string _proof, address indexed _addr, bytes32 _id);
  event NameAddressProofRegistered(string _name, address indexed _addr, string _proof);
  event RegistrarError(address indexed _addr, bytes32 _id, string _result, string _message);
  event AddressMismatch(address _actual, address indexed _addr);
  event InsufficientFunds(uint _funds, uint _cost, address indexed _addr);

  mapping (address => string) addrToName;
  mapping (string => address) nameToAddr;
  mapping (address => string) addrToProof;
  mapping (string => string) nameToProof;

  RegistrarI registrar;

  modifier onlyRegistrar {
    if (msg.sender != address(registrar)) throw;
      _;
  }

  function RedditRegistry() {
    registrar = RegistrarFactory.newURLRegistrar();
  }

  function lookupAddr(address _addr) public constant returns(string name, string proof) {
    return (addrToName[_addr], addrToProof[_addr]);
  }

  function lookupName(string _name) public constant returns(address addr, string proof) {
    return (nameToAddr[_name], nameToProof[_name]);
  }

  function register(string _proof, address _addr) public payable returns(bytes32 oracleId) {

      //_addr not strictly needed - but we use it to do an upfront check to avoid wasted oracle queries
      if (msg.sender != _addr) {
        AddressMismatch(msg.sender, _addr);
        return;
      }

      uint cost = registrar.getCost();
      if (cost > this.balance) {
        InsufficientFunds(this.balance, cost, _addr);
        return;
      }

      bytes32 id = registrar.register.value(this.balance)(_proof, _addr);
      RegistrationSent(_proof, _addr, id);
      return id;

  }

  function getCost() public payable returns(uint cost) {
    return registrar.getCost();
  }

  function update(string _name, address _addr, string _proof) onlyRegistrar {
    addrToName[_addr] = _name;
    nameToAddr[_name] = _addr;
    addrToProof[_addr] = _proof;
    nameToProof[_name] = _proof;
    NameAddressProofRegistered(_name, _addr, _proof);
  }

  function error(bytes32 _id, address _addr, string _result, string _message) onlyRegistrar {
    RegistrarError(_addr, _id, _result, _message);
  }

}
