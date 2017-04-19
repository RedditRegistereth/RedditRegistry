var RedditRegister = artifacts.require("./RedditRegister.sol");

contract('RedditRegister', function(accounts) {
  it("should show no registration for adamaid_321 name", function() {
    return RedditRegister.deployed().then(function(instance) {
      return instance.lookupName.call("adamaid_321");
    }).then(function(address) {
      assert.equal(address.valueOf(), 0, "adamaid_321 should not be registered");
    });
  });
  it("should show no registration for 0x9a9d8ff9854a2722a76a99de6c1bb71d93898ef5 addr", function() {
    return RedditRegister.deployed().then(function(instance) {
      return instance.lookupAddr.call("0x9a9d8ff9854a2722a76a99de6c1bb71d93898ef5");
    }).then(function(name) {
      assert.equal(name, "", "0x9a9d8ff9854a2722a76a99de6c1bb71d93898ef5 should not be registered");
    });
  });
  it("register 0x9a9d8ff9854a2722a76a99de6c1bb71d93898ef5 addr to adamaid_321 name", function() {
    //This doesn't work due to asynchronous nature of register
    var account_one = web3.eth.accounts[0];
    var account_two = web3.eth.accounts[1];
    var redditRegister;
    return RedditRegister.deployed().then(function(instance) {
      redditRegister = instance;
      return redditRegister.register("665zap", "0x9a9d8ff9854a2722a76a99de6c1bb71d93898ef5", {from: account_one, value: 300});
    }).then(function(tx_id) {
      var x = 0;
      var interval = setInterval(function() {
        return redditRegister.lookupAddr.call("0x9a9d8ff9854a2722a76a99de6c1bb71d93898ef5")
      }).then(function(name) {
        assert.equal(name, "adamaid_321", "0x9a9d8ff9854a2722a76a99de6c1bb71d93898ef5 should be registered");
      }, 1000);
    });
  });
});
