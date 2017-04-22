pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/RedditRegister.sol";

contract TestRedditRegister is RedditRegister {

  string proof_1 = "proof_1";
  address addr_1 = 0x9a9d8ff9854a2722a76a99de6c1bb71d93898ef5;
  bytes32 oracleId_1 = "0x01";
  string name_1 = "user_1";

  string proof_2 = "proof_2";
  address addr_2 = 0x109d8ff9854a2722a76a99de6c1bb71d93898ef5;
  bytes32 oracleId_2 = "0x02";
  string name_2 = "user_2";

  string emptyString = "";
  address emptyAddress = 0x0;

  function beforeEach() {

    //Clear variables
    addrToName[addr_1] = emptyString;
    nameToAddr[name_1] = emptyAddress;
    addrToProof[addr_1] = emptyString;
    nameToProof[name_1] = emptyString;
    oracleExpectedAddress[oracleId_1] = emptyAddress;
    oracleProof[oracleId_1] = emptyString;
    oracleCallbackComplete[oracleId_1] = false;

    addrToName[addr_2] = emptyString;
    nameToAddr[name_2] = emptyAddress;
    addrToProof[addr_2] = emptyString;
    nameToProof[name_2] = emptyString;
    oracleExpectedAddress[oracleId_2] = emptyAddress;
    oracleProof[oracleId_2] = emptyString;
    oracleCallbackComplete[oracleId_2] = false;

    //Mimic the register function here
    oracleExpectedAddress[oracleId_1] = addr_1;
    oracleProof[oracleId_1] = proof_1;

    oracleExpectedAddress[oracleId_2] = addr_2;
    oracleProof[oracleId_2] = proof_2;

  }

  function checkData(address addrInput, string nameInput, bytes32 oracleIdInput, address addrExpected, string nameExpected, string addrProofExpected, string nameProofExpected) {
    string memory nameResponse;
    string memory nameProofResponse;
    (nameResponse, nameProofResponse) = lookupAddr(addrInput);
    Assert.equal(nameResponse, nameExpected, "Name values unexpected");
    address addrResponse;
    string memory addrProofResponse;
    (addrResponse, addrProofResponse) = lookupName(nameInput);
    Assert.equal(addrResponse, addrExpected, "Address values unexpected");
    Assert.equal(addrProofResponse, addrProofExpected, "Proof should have registered");
    Assert.equal(nameProofResponse, nameProofExpected, "Proof should have registered");
    Assert.equal(oracleCallbackComplete[oracleIdInput], true, "Callback should have triggered");

  }

  function testCallback() {

    //Mixed case input
    _callback(oracleId_1, '["user_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    checkData(addr_1, name_1, oracleId_1, addr_1, name_1, proof_1, proof_1);

    //Do another one
    _callback(oracleId_2, '["user_2", "0x109d8ff9854a2722a76a99de6c1bb71d93898ef5"]');
    checkData(addr_2, name_2, oracleId_2, addr_2, name_2, proof_2, proof_2);

  }

  function testCallback_wrong_length_address() {
    _callback(oracleId_1, '["user_1", "0x9a9FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    checkData(addr_1, name_1, oracleId_1, emptyAddress, emptyString, emptyString, emptyString);
  }

  function testCallback_nonArray() {
    _callback(oracleId_1, '"user_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"');
    checkData(addr_1, name_1, oracleId_1, emptyAddress, emptyString, emptyString, emptyString);
  }

  function testCallback_empty() {
    _callback(oracleId_1, '');
    checkData(addr_1, name_1, oracleId_1, emptyAddress, emptyString, emptyString, emptyString);
  }

  function testCallback_goodAndBad() {

    //Do a good one - we user _2 here as testCallback_empty expects _1 to be clean
    _callback(oracleId_2, '["user_2", "0x109d8ff9854a2722a76a99de6c1bb71d93898ef5"]');
    checkData(addr_2, name_2, oracleId_2, addr_2, name_2, proof_2, proof_2);

    //Do a bad one
    testCallback_empty();

    //Check first good one is still good
    checkData(addr_2, name_2, oracleId_2, addr_2, name_2, proof_2, proof_2);

    //Do another good one
    _callback(oracleId_1, '["user_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    checkData(addr_1, name_1, oracleId_1, addr_1, name_1, proof_1, proof_1);

  }

  function testCallback_changeName() {

    //First name updated
    _callback(oracleId_1, '["user_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    checkData(addr_1, name_1, oracleId_1, addr_1, name_1, proof_1, proof_1);

    //Second name registered
    bytes32 oracleId_1_1 = "0x03";
    string memory name_1_1 = "user_1_1";
    string memory proof_1_1 = "proof_1_1";
    oracleExpectedAddress[oracleId_1_1] = addr_1;
    oracleProof[oracleId_1_1] = proof_1_1;

    //Change name to "user_1_1"
    _callback(oracleId_1_1, '["user_1_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    checkData(addr_1, name_1_1, oracleId_1_1, addr_1, name_1_1, proof_1_1, proof_1_1);

    //Check that original name is still mapped
    checkData(addr_1, name_1, oracleId_1, addr_1, name_1_1, proof_1, proof_1_1);

  }

  function testCallback_changeAddress() {

    //First address updated
    _callback(oracleId_1, '["user_1", "0x9a9d8FF9854a2722a76a99de6c1Bb71d93898eF5"]');
    checkData(addr_1, name_1, oracleId_1, addr_1, name_1, proof_1, proof_1);

    //Second address registered
    bytes32 oracleId_1_1 = "0x03";
    address addr_1_1 = 0x209d8ff9854a2722a76a99de6c1bb71d93898ef5;
    string memory proof_1_1 = "proof_1_1";
    oracleExpectedAddress[oracleId_1_1] = addr_1_1;
    oracleProof[oracleId_1_1] = proof_1_1;

    //Change addr to "0x209d8ff9854a2722a76a99de6c1bb71d93898ef5"
    _callback(oracleId_1_1, '["user_1", "0x209d8ff9854a2722a76a99de6c1bb71d93898ef5"]');
    checkData(addr_1_1, name_1, oracleId_1_1, addr_1_1, name_1, proof_1_1, proof_1_1);

    //Check that original name is still mapped
    checkData(addr_1, name_1, oracleId_1, addr_1_1, name_1, proof_1_1, proof_1);

  }

}
