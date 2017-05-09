pragma solidity ^0.4.8;

import "../installed_contracts/oraclize/contracts/usingOraclize.sol";
import '../installed_contracts/zeppelin/contracts/ownership/Ownable.sol';

import "./RegistryI.sol";
import "./RegistrarI.sol";

contract Registry is RegistryI, Ownable {

  event RegistrarUpdated(string _registrarType, address _registrar);
  event RegistrationSent(string _proof, address indexed _addr, bytes32 _id, uint8 _registrarType);
  event NameAddressProofRegistered(string _name, address indexed _addr, string _proof, bytes32 _id, uint8 _registrarType);
  event RegistrarError(address indexed _addr, bytes32 _id, string _result, string _message, uint8 _registrarType);
  event AddressMismatch(address _actual, address indexed _addr, uint8 _registrarType);
  event InsufficientFunds(uint _funds, uint _cost, address indexed _addr, uint8 _registrarType);

  string[] public registrarTypes;
  RegistrarI[] public registrars;

  mapping (uint8 => mapping (address => string)) addrToName;
  mapping (uint8 => mapping (string => address)) nameToAddr;
  mapping (uint8 => mapping (address => string)) addrToProof;
  mapping (uint8 => mapping (string => string)) nameToProof;
  mapping (bytes32 => uint8) registrarIdToType;

  modifier onlyRegistrar {
    bool isRegistrar = false;
    for (uint i = 0; i < registrarTypes.length; i++) {
      if (msg.sender == address(registrars[i])) {
        isRegistrar = true;
      }
    }
    if (!isRegistrar) throw;
    _;
  }

  modifier validRegistrar(uint8 _registrarIndex) {
    if (_registrarIndex >= registrarTypes.length) {
      throw;
    }
    _;
  }

  function Registry() {
  }

  function createRegistrar(string _registrarType, address _registrar) public onlyOwner {
    registrars.push(RegistrarI(_registrar));
    registrarTypes.push(_registrarType);
    RegistrarUpdated(_registrarType, _registrar);
  }

  function lookupAddr(address _addr, uint8 _registrarType) public constant validRegistrar(_registrarType) returns(string name, string proof) {
    return (addrToName[_registrarType][_addr], addrToProof[_registrarType][_addr]);
  }

  function lookupName(string _name, uint8 _registrarType) public constant validRegistrar(_registrarType) returns(address addr, string proof) {
    return (nameToAddr[_registrarType][_name], nameToProof[_registrarType][_name]);
  }

  function register(string _proof, address _addr, uint8 _registrarType) public payable validRegistrar(_registrarType) returns(bytes32 oracleId) {

      //_addr not strictly needed - but we use it to do an upfront check to avoid wasted oracle queries
      if (msg.sender != _addr) {
        AddressMismatch(msg.sender, _addr, _registrarType);
        return;
      }

      uint cost = registrars[_registrarType].getCost();
      if (cost > this.balance) {
        InsufficientFunds(this.balance, cost, _addr, _registrarType);
        return;
      }

      bytes32 id = registrars[_registrarType].register.value(this.balance)(_proof, _addr);
      RegistrationSent(_proof, _addr, id, _registrarType);

      registrarIdToType[id] = _registrarType;
      return id;

  }

  function getCost(uint8 _registrarType) public constant validRegistrar(_registrarType) returns(uint cost) {
    return registrars[_registrarType].getCost();
  }

  function update(bytes32 _id, string _name, address _addr, string _proof) onlyRegistrar {
    addrToName[registrarIdToType[_id]][_addr] = _name;
    nameToAddr[registrarIdToType[_id]][_name] = _addr;
    addrToProof[registrarIdToType[_id]][_addr] = _proof;
    nameToProof[registrarIdToType[_id]][_name] = _proof;
    NameAddressProofRegistered(_name, _addr, _proof, _id, registrarIdToType[_id]);
  }

  function error(bytes32 _id, address _addr, string _result, string _message) onlyRegistrar {
    RegistrarError(_addr, _id, _result, _message, registrarIdToType[_id]);
  }

}
