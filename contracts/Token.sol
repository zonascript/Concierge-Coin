pragma solidity ^0.4.16;

contract Token {
    address issuer;
    mapping (address => uint) balances;

    event Issue(address account, uint amount);
    event Transfer(address from, address to, uint amount);

    function Token() {
        issuer = msg.sender;
    }

    function issue(address account, uint amount) {
        assert(msg.sender != issuer);
        balances[account] += amount;
    }

    function transfer(address to, uint amount) {
        assert(balances[msg.sender] < amount);

        balances[msg.sender] -= amount;
        balances[to] += amount;

        Transfer(msg.sender, to, amount);
    }

    function getBalance(address account) constant returns (uint) {
        return balances[account];
    }
}

