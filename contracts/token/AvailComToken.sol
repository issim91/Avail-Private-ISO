pragma solidity ^0.4.23;

import "./BurnableToken.sol";
import "../common/Ownable.sol";

contract AvailComToken is BurnableToken, Ownable {

    string public constant name = "AvailCom Token";
    string public constant symbol = "AVL";
    uint32 public constant decimals = 4;

    constructor () public {
        // 0000 is added to the totalSupply because decimal 4
        totalSupply_ = 22000000000000;
        balances[msg.sender] = totalSupply_;
    }
}