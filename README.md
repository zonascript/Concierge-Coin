# Ethereum Bootstrap

Through the methods described in this article and the script, we can quickly build our own private chain for development testing.

The repository contains the following tools:

* A test account import script that imports five test account private keys into the Ether Square node during the first deployment.
* A genesis.json configuration file, corresponding to five test accounts to provide initial funding (Concierge currency), to facilitate the development of testing.
* A script that quickly starts a private chain node and enters interactive mode.
* A sample：`contracts/Token.sol`。This is an intelligent contract written using the contract language [Solidity](http://solidity.readthedocs.org/en/latest/)The Token contract's function is to issue a token (which can be understood as money, points, etc.). Only the creator of the contract has the right to issue, the owner of the token has the right to use, and is free to transfer.

**Test account private key is public data placed on Github, do not use in the official environment or public chain. If you use these private keys outside the test environment, your funds will be stolen! Instead use a wallet program to generate some test accounts**

## Setup

1. In the installation folder of [go-ethereum](https://github.com/ethereum/go-ethereum) and [solc](http://solidity.readthedocs.org/en/latest/), can run `geth`and`solc`
2. Using `git clone` to download this repository to local
3. Install [expect](http://expect.sourceforge.net/)

## Start geth

1. Go to this: `cd ethereum-bootstrap`
2. Import test accounts: `./bin/import_keys.sh`
3. Initialize blockchain: `./bin/private_blockchain_init.sh`
   The output is as follow：
   ```
    I0822 16:28:29.767646 ethdb/database.go:82] Alloted 16MB cache and 16 file handles to data/chaindata
    I0822 16:28:29.773596 cmd/geth/main.go:299] successfully wrote genesis block and/or chain rule set: 19425866b7d3298a15ad79accf302ba9d21859174e7ae99ce552e05f13f0efa3
   ```
4. To solve the problem account is lock, modify the file bin/private_blockchain.sh, add --unlock 0 --password value after geth,
   where value is the file address of the password you created that contains the password you set in step 2
5. Start the private chain node: `./bin/private_blockchain.sh`. The result is as follow:
  ![private-started.png](screenshots/private-started.png)
6. At this point the etherbox interactive console has been launched, we can start testing and development.

Note: The tool script assumes that your `geth` is installed in the default location and can be passed directly geth. If the geth command is installed in a non-standard location, you can set the `GETH` environment variable to specify the path of the geth executable file. E.g:

`GETH=/some/weird/dir/geth ./bin/import_keys.sh`

## Publish ether by digging for account
View account balance：
```
> web3.eth.getBalance(web3.eth.accounts[0])
0
```
You can mine ether:
```
> miner.start(1)
I0822 17:17:43.496826 miner/miner.go:119] Starting mining operation (CPU=1 TOT=3)
I0822 17:17:43.497379 miner/worker.go:573] commit new work on block 30 with 0 txs & 1 uncles. Took 527.407µs
```
Call miner.stop to stop mining:
```
> miner.stop()
true
> web3.eth.getBalance(web3.eth.accounts[0])
309531250000000000000
```
Unlock account to use
```
> personal.unlockAccount(web3.eth.accounts[0])
```

## Use the Etherbox Console to compile and deploy smart contracts

In the `contracts` directory there is a smart contract sample file `Token.sol`, through the Solarse language to achieve the basic tokens function, contract holders can issue tokens, the user can transfer to each other.

We can use the etherbox console to compile and deploy this contract. The etherbox console is the most basic tool that will be cumbersome to use. The community also provides other more convenient deployment tools that are not discussed here.

The first step, we first contract code compressed into a line. Create a new ssh session, switch to geth user environment `su - geth`, and then enter: `cat contracts/Token.sol | tr '\n' ' '`(This step is to eliminate the line to extract the contract code can be directly in the terminal, but also directly copy the code behind)

Switch to the etherbox console, save the contract code as a variable:

```javascript
var tokenSource = 'contract Token {     address issuer;     mapping (address => uint) balances;      event Issue(address account, uint amount);     event Transfer(address from, address to, uint amount);      function Token() {         issuer = msg.sender;     }      function issue(address account, uint amount) {         if (msg.sender != issuer) throw;         balances[account] += amount;     }      function transfer(address to, uint amount) {         if (balances[msg.sender] < amount) throw;          balances[msg.sender] -= amount;         balances[to] += amount;          Transfer(msg.sender, to, amount);     }      function getBalance(address account) constant returns (uint) {         return balances[account];     } }';
```

Then compile the contract code:

```javascript
var tokenCompiled = web3.eth.compile.solidity(tokenSource);
```

Type `tokenCompiled['<stdin>:Token'].code`to see the complied code
Type `tokenCompiled['<stdin>:Token'].info.abiDefinition`you can see the [ABI](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI)．

Next we will deploy the compiled contract to the network.

First we use ABI to create a contract object in a javascript environment:

```javascript
var contract = web3.eth.contract(tokenCompiled['<stdin>:Token'].info.abiDefinition);
```

We deploy contract through contract object:

```javascript
var initializer = {from: web3.eth.accounts[0], data: tokenCompiled['<stdin>:Token'].code, gas: 300000};

var callback = function(e, contract){
    if(!e) {
      if(!contract.address) {
        console.log("Contract transaction send: TransactionHash: " + contract.transactionHash + " waiting to be mined...");
      } else {
        console.log("Contract mined!");
        console.log(contract);
      }
    }
};

var token = contract.new(initializer, callback);
```

`contract.new`The first parameter of the method sets the creator address `from` of the new contract, the code `data` for the new contract, and the cost of creating the new contract `gas`. `gas` Is an estimate, as long as more than the required gas can be, after the completion of the contract to complete the gas will be returned to the contract creator.

`contract.new`The second parameter of the method sets a callback function that tells us whether the deployment was successfully.

`contract.new`The implementation will prompt you to enter the wallet password. After the success of the implementation of our contract Token has been broadcast to the network. At this point as long as the miners waiting for our contract to save the stack to the ether square block, the deployment is complete.

In the public chain, miners pack an average of 15 seconds, in the private chain, we need to do this thing. First open mining:

```javascript
miner.start(1)
```

At this point need to wait for some time, the ether square node will generate the necessary data mining, these data will be placed inside the memory. After the data is generated, the mining will begin and will be seen later in the console output:

```
:hammer:Mined block
```

Of the information, which shows that dug a block, the contract has been deployed to the ether square network! At this point we can mine off:

```javascript
miner.stop()
```

Then we can call the contract. First through the `token.address` contract to be deployed to the address, after the new contract object can be used. Here we use the original contract object:

```
// get the balance of the first acount
> web3.eth.getBalance(web3.eth.accounts[0])
0

// Send 100 token to the local wallet's first address
> token.issue.sendTransaction(web3.eth.accounts[0], 100, {from: web3.eth.accounts[0]});
I1221 11:48:30.512296   11155 xeth.go:1055] Tx(0xc0712460a826bfea67d58a30f584e4bebdbb6138e7e6bc1dbd6880d2fce3a8ef) to: 0x37dc85ae239ec39556ae7cc35a129698152afe3c
"0xc0712460a826bfea67d58a30f584e4bebdbb6138e7e6bc1dbd6880d2fce3a8ef"

// Issuing a token is a transaction, so it needs to be mined to make it effective
> miner.start(1)
:hammer:Mined block
> miner.stop()

// Query the balance of the first address of the local wallet
> token.getBalance(web3.eth.accounts[0])
100

// Send from the first address 30 token to the second address of the local wallet
> token.transfer.sendTransaction(web3.eth.accounts[1], 30, {from: web3.eth.accounts[0]})
I1221 11:53:31.852541   11155 xeth.go:1055] Tx(0x1d209cef921dea5592d8604ac0da680348987b131235943e372f8df35fd43d1b) to: 0x37dc85ae239ec39556ae7cc35a129698152afe3c
"0x1d209cef921dea5592d8604ac0da680348987b131235943e372f8df35fd43d1b"
> miner.start(1)
> miner.stop()
> token.getBalance(web3.eth.accounts[0])
70
> token.getBalance(web3.eth.accounts[1])
30
```

## Other

All the data in the private chain will be placed in the root directory of the warehouse directory data, delete the directory can clear all the data, restart the new environment. you can use this gadget to deploy, more convenient:
[solidity_compiler_helper](https://github.com/rakeshbs/solidity_compiler_helper)


For more information about the Ether Square, visit [EthFans](http://ethfans.org).
