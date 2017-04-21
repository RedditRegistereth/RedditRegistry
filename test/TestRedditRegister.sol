pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/RedditRegister.sol";

contract TestRedditRegister is RedditRegister {

  string hash_1 = "hash_1";
  address addr_1 = 0x9a9d8ff9854a2722a76a99de6c1bb71d93898ef5;
  bytes32 oracleId_1 = "0x01";
  string name_1 = "user_1";

  string hash_2 = "hash_2";
  address addr_2 = 0x109d8ff9854a2722a76a99de6c1bb71d93898ef5;
  bytes32 oracleId_2 = "0x02";
  string name_2 = "user_2";

  string emptyString = "";
  address emptyAddress = 0x0;

  function beforeEach() {

    //Clear variables
    addrToName[addr_1] = emptyString;
    nameToAddr[name_1] = emptyAddress;
    addrToHash[addr_1] = emptyString;
    oracleExpectedAddress[oracleId_1] = emptyAddress;
    oracleHash[oracleId_1] = emptyString;
    oracleCallbackComplete[oracleId_1] = false;

    addrToName[addr_2] = emptyString;
    nameToAddr[name_2] = emptyAddress;
    addrToHash[addr_2] = emptyString;
    oracleExpectedAddress[oracleId_2] = emptyAddress;
    oracleHash[oracleId_2] = emptyString;
    oracleCallbackComplete[oracleId_2] = false;

    //Mimic the register function here
    oracleExpectedAddress[oracleId_1] = addr_1;
    oracleHash[oracleId_1] = hash_1;

    oracleExpectedAddress[oracleId_2] = addr_2;
    oracleHash[oracleId_2] = hash_2;

  }

  function testCallback() {

    //Mixed case input
    _callback(oracleId_1, '["user_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    string memory nameResponse_1 = lookupAddr(addr_1);
    Assert.equal(nameResponse_1, name_1, "Name should have registered");
    address addrResponse_1 = lookupName(name_1);
    Assert.equal(addrResponse_1, addr_1, "Address should have registered");
    string memory hashResponse_1 = lookupHash(addr_1);
    Assert.equal(hashResponse_1, hash_1, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_1], true, "Callback should not have triggered");

    //Do another one
    _callback(oracleId_2, '["user_2", "0x109d8ff9854a2722a76a99de6c1bb71d93898ef5"]');
    string memory nameResponse_2 = lookupAddr(addr_2);
    Assert.equal(nameResponse_2, name_2, "Name should have registered");
    address addrResponse_2 = lookupName(name_2);
    Assert.equal(addrResponse_2, addr_2, "Address should have registered");
    string memory hashResponse_2 = lookupHash(addr_2);
    Assert.equal(hashResponse_2, hash_2, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_2], true, "Callback should not have triggered");

  }

  function testCallback_wrong_length_address() {
    _callback(oracleId_1, '["user_1", "0x9a9FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    string memory name = lookupAddr(addr_1);
    Assert.equal(name, emptyString, "Name should have not have registered");
    address addr = lookupName(name_1);
    Assert.equal(addr, emptyAddress, "Address should have not have registered");
    string memory hash = lookupHash(addr_1);
    Assert.equal(hash, emptyString, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_1], true, "Callback should not have triggered");
  }

  function testCallback_nonArray() {
    _callback(oracleId_1, '"user_1", "0x9a9d8ff9854a2722a76a99de6c1bb71d93898ef5"');
    string memory name = lookupAddr(addr_1);
    Assert.equal(name, emptyString, "Name should have not have registered");
    address addr = lookupName(name_1);
    Assert.equal(addr, emptyAddress, "Address should have not have registered");
    string memory hash = lookupHash(addr_1);
    Assert.equal(hash, emptyString, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_1], true, "Callback should not have triggered");
  }

  function testCallback_empty() {
    _callback(oracleId_1, '');
    string memory name = lookupAddr(addr_1);
    Assert.equal(name, emptyString, "Name should have not have registered");
    address addr = lookupName(name_1);
    Assert.equal(addr, emptyAddress, "Address should have not have registered");
    string memory hash = lookupHash(addr_1);
    Assert.equal(hash, emptyString, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_1], true, "Callback should not have triggered");
  }

  function testCallback_goodAndBad() {

    //Do a good one - we user _2 here as testCallback_empty expects _1 to be clean
    _callback(oracleId_2, '["user_2", "0x109d8ff9854a2722a76a99de6c1bb71d93898ef5"]');
    string memory nameResponse_2 = lookupAddr(addr_2);
    Assert.equal(nameResponse_2, name_2, "Name should have registered");
    address addrResponse_2 = lookupName(name_2);
    Assert.equal(addrResponse_2, addr_2, "Address should have registered");
    string memory hashResponse_2 = lookupHash(addr_2);
    Assert.equal(hashResponse_2, hash_2, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_2], true, "Callback should not have triggered");

    //Do a bad one
    testCallback_empty();

    //Check first good one is still good
    string memory nameResponse_2_1 = lookupAddr(addr_2);
    Assert.equal(nameResponse_2_1, name_2, "Name should have registered");
    address addrResponse_2_1 = lookupName(name_2);
    Assert.equal(addrResponse_2_1, addr_2, "Address should have registered");
    string memory hashResponse_2_1 = lookupHash(addr_2);
    Assert.equal(hashResponse_2_1, hash_2, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_2], true, "Callback should not have triggered");

    //Do another good one
    _callback(oracleId_1, '["user_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    string memory nameResponse_1 = lookupAddr(addr_1);
    Assert.equal(nameResponse_1, name_1, "Name should have registered");
    address addrResponse_1 = lookupName(name_1);
    Assert.equal(addrResponse_1, addr_1, "Address should have registered");
    string memory hashResponse_1 = lookupHash(addr_1);
    Assert.equal(hashResponse_1, hash_1, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_1], true, "Callback should not have triggered");

  }

  function testCallback_changeName() {

    //Mixed case input
    _callback(oracleId_1, '["user_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    string memory nameResponse_1 = lookupAddr(addr_1);
    Assert.equal(nameResponse_1, name_1, "Name should have registered");
    address addrResponse_1 = lookupName(name_1);
    Assert.equal(addrResponse_1, addr_1, "Address should have registered");
    string memory hashResponse_1 = lookupHash(addr_1);
    Assert.equal(hashResponse_1, hash_1, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_1], true, "Callback should not have triggered");

    bytes32 oracleId_1_1 = "0x03";
    string memory name_1_1 = "user_1_1";
    string memory hash_1_1 = "hash_1_1";
    oracleExpectedAddress[oracleId_1_1] = addr_1;
    oracleHash[oracleId_1_1] = hash_1_1;

    //Change name to "user_1_1"
    _callback(oracleId_1_1, '["user_1_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    string memory nameResponse_1_1 = lookupAddr(addr_1);
    Assert.equal(nameResponse_1_1, name_1_1, "Name should have registered");
    address addrResponse_1_1 = lookupName(name_1_1);
    Assert.equal(addrResponse_1_1, addr_1, "Address should have registered");
    string memory hashResponse_1_1 = lookupHash(addr_1);
    Assert.equal(hashResponse_1_1, hash_1_1, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_1_1], true, "Callback should not have triggered");

  }

  function testCallback_changeAddress() {

    //Mixed case input
    _callback(oracleId_1, '["user_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    string memory nameResponse_1 = lookupAddr(addr_1);
    Assert.equal(nameResponse_1, name_1, "Name should have registered");
    address addrResponse_1 = lookupName(name_1);
    Assert.equal(addrResponse_1, addr_1, "Address should have registered");
    string memory hashResponse_1 = lookupHash(addr_1);
    Assert.equal(hashResponse_1, hash_1, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_1], true, "Callback should not have triggered");

    bytes32 oracleId_1_1 = "0x03";
    address addr_1_1 = 0x209d8ff9854a2722a76a99de6c1bb71d93898ef5;
    string memory hash_1_1 = "hash_1_1";
    oracleExpectedAddress[oracleId_1_1] = addr_1_1;
    oracleHash[oracleId_1_1] = hash_1_1;

    //Change name to "user_1_1"
    _callback(oracleId_1_1, '["user_1", "0x209d8ff9854a2722a76a99de6c1bb71d93898ef5"]');
    string memory nameResponse_1_1 = lookupAddr(addr_1_1);
    Assert.equal(nameResponse_1_1, name_1, "Name should have registered");
    address addrResponse_1_1 = lookupName(name_1);
    Assert.equal(addrResponse_1_1, addr_1_1, "Address should have registered");
    string memory hashResponse_1_1 = lookupHash(addr_1_1);
    Assert.equal(hashResponse_1_1, hash_1_1, "Hash should have registered");
    Assert.equal(oracleCallbackComplete[oracleId_1_1], true, "Callback should not have triggered");

  }

}
