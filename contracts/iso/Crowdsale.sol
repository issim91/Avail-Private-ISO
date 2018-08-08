pragma solidity ^0.4.23;

import "../token/AvailComToken.sol";
import "../common/SafeMath.sol";
import "../common/Whitelist.sol";


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Ownable, Whitelist {
  using SafeMath for uint256;

  // The token being sold
  AvailComToken public token;

  // Variable for tracking whether ISO is complete
  bool public fifishISO = false;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Start time for test contract
  uint public start = 1533081600; // 1.08.2018
  // uint public start = 1534291200; // 15.08.2018

  uint public period = 30;
  uint public hardcap = 400 * 1 ether;

  // Bonus on the closed sale of tokens - 50%
  uint public bonusPersent = 50;

  // Amount of wei raised
  uint256 public weiRaised;

  // The minimum purchase amount of tokens. Can be changed during ISO
  uint256 public etherLimit = 1 ether;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // Time check modifier
    modifier saleIsOn() {
    	require(now > start && now < start + period * 1 days);
    	_;
    }
    
    // Check modifier on the collected hardcap
    modifier isUnderHardCap() {
        require(wallet.balance <= hardcap);
        _;
    }

  /**
   * @param _token Address of the token being sold
   */
  constructor (AvailComToken _token) public {
    require(_token != address(0));

    // 0000 is added to the rate because decimal 4
    rate = 167000000;
    wallet = msg.sender;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () saleIsOn isUnderHardCap external payable {
    require(!fifishISO);

    if (!hasRole(msg.sender, ROLE_WHITELISTED)) {
      require(msg.value >= etherLimit);
    }

    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _forwardFunds();
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    // Adding a bonus tokens to purchase
    _tokenAmount = _tokenAmount + (_tokenAmount * bonusPersent / 100);
    // Сonversion from wei
    _tokenAmount = _tokenAmount / 1000000000000000000;
    token.transfer(_beneficiary, _tokenAmount);
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // ISO completion function. 
  // At the end of ISO all unallocated tokens are returned to the address of the creator of the contract
  function finishCrowdsale() public onlyOwner {
    uint _value = token.balanceOf(this);
    token.transfer(wallet, _value);
    fifishISO = true;
  }

  // The function of changing the minimum purchase amount of tokens.
  function editEtherLimit (uint256 _value) public onlyOwner {
    etherLimit = _value;
    etherLimit = etherLimit * 1 ether;
  }
}