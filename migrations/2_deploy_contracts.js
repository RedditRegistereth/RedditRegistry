var Registry = artifacts.require("./Registry.sol");
var RedditRegistrarComputation = artifacts.require("./RedditRegistrarComputation.sol")
var GithubRegistrarComputation = artifacts.require("./GithubRegistrarComputation.sol")

module.exports = function(deployer) {
  var registry;
  deployer.deploy(Registry).then(function() {
    return deployer.deploy(RedditRegistrarComputation, Registry.address);
  }).then(function() {
    return deployer.deploy(GithubRegistrarComputation, Registry.address);
  }).then(function() {
    return Registry.deployed();
  }).then(function(instance) {
    registry = instance;
    return registry.createRegistrar("reddit", RedditRegistrarComputation.address);
  }).then(function(txId) {
    return registry.createRegistrar("github", GithubRegistrarComputation.address);
  });
};



// var OraclizeAPI = artifacts.require("./OraclizeAPI.sol");
//
// module.exports = function(deployer) {
//   deployer.deploy(OraclizeAPI);
// };
