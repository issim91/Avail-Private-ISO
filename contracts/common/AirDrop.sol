pragma solidity ^0.4.23;

import "../token/AvailComToken.sol";
import "./Ownable.sol";

contract AirDrop is Ownable {

AvailComToken public token;

    constructor (AvailComToken _token) public {
        require(_token != address(0));
        token = _token;
    }

    function dropTokens (address[] holdersAddresses, uint256[] balancesValues) public onlyOwner {
        for (uint i = 0; i < holdersAddresses.length; i++) {
            uint amount = balancesValues[i];
            address holderAddr = holdersAddresses[i];
            if(amount > 0) {
                token.transfer(holderAddr, amount);
            }
        }
    }

}