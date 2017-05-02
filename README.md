# RedditRegister

## Building

1. Start testrpc using `testrpc --gasLimit 100000000`. Larger gas is needed to execute test contract. Set `gas: 99000000` in truffle.js
1. Run `truffle compile`, then run `truffle migrate` to deploy the contracts onto testrpc network.
1. Then run `truffle test` to run tests.
1. To run the basic web frontend, you can run `npm run dev`.

## Frontend

* GUI deployed at: https://ipfs.io/ipfs/QmcHun2psVr1ZAuQmPanHT3Scup8o1dUC88t1JJHNxhiVp/

## Some notes

* The register function requires payment in order to fund the Oraclize queries. If the RedditRegister contract does not have sufficient funds it will return false. Excess or insufficient funds are not returned to the caller, but maintained by the contract to help with future calls. No funds can ever be directly withdrawn from the contract.

* Possibly the contract should be upgradable (or at least the logic used to validate users). Upgrade could be done based on a vote of existing registered users (although it is cheap to create reddit & ethereum accounts, there is a cost to register them with the contract, so some incentive not to register lots of accounts in order to vote maliciously).

* It is possible for Oraclize to return an empty result representing an error from Reddit. This can happen if, for example, Reddit is throttling Oraclize requests at that moment. This seems relatively rare.

* The contract is designed not to throw unless something very unexpected happens. Generally it will use Events to record any activity and issues, including e.g. the above.

* Unit tests cover behaviour of Oraclize callback function, but not the Register function (which is trivial). This is because doing so would require deploying to a network running Oraclize contracts, or using the ethereum-bridge and dealing with asyncronous responses.

* Calls to lookupAddr / lookupName will always return the most recently registered name / address respectively. Old addresses / names can still be passed to lookupAddr / Name and you will receive back valid names / addresses. Passing the returned name / address back into the lookupName / lookupAddr and comparing the response with the original input will tell you whether the registration is the most recent for the given original address / name.

## Expected test output

```shell
test ./test/TestRedditRegister.sol
Using network 'development'.

Compiling ./contracts/RedditRegister.sol...
Compiling ./installed_contracts/oraclize/contracts/usingOraclize.sol...
Compiling ./test/TestRedditRegister.sol...
Compiling truffle/Assert.sol...
Compiling truffle/DeployedAddresses.sol...


  TestRedditRegister
    ✓ testCallback (1318ms)
    ✓ testCallback_wrong_length_address (324ms)
    ✓ testCallback_nonArray (191ms)
    ✓ testCallback_empty (189ms)
    ✓ testCallback_goodAndBad (1109ms)
    ✓ testCallback_changeName (743ms)
    ✓ testCallback_changeAddress (803ms)


  7 passing (6s)
```
