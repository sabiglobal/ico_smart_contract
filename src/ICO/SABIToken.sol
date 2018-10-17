pragma solidity ^0.4.24;

import '../common/Ownable.sol';
import '../common/ERC223.sol';

/**
 * @title SABIGlobal Token based on ERC223 token
 */
contract SABIToken is ERC223 {
	
  uint public initialSupply = 1400 * 10**6; // 1.4 billion

  /** Name and symbol were updated. */
  event UpdatedTokenInformation(string _name, string _symbol);

  constructor(string _name, string _symbol, address _crowdsale, address _team, address _bounty, address _adviser, address _developer) public {
    name = _name;
    symbol = _symbol;
    decimals = 8;
    crowdsale = _crowdsale;

    bytes memory empty;    
    totalSupply = initialSupply*uint(10)**decimals;
    // creating initial tokens
    balances[_crowdsale] = totalSupply;    
    emit Transfer(0x0, _crowdsale, balances[_crowdsale], empty);
    
    // send 15% - to team account
    uint value = safePerc(totalSupply, 1500);
    balances[_crowdsale] = safeSub(balances[_crowdsale], value);
    balances[_team] = value;
    emit Transfer(_crowdsale, _team, balances[_team], empty);  

    // send 5% - to bounty account
    value = safePerc(totalSupply, 500);
    balances[_crowdsale] = safeSub(balances[_crowdsale], value);
    balances[_bounty] = value;
    emit Transfer(_crowdsale, _bounty, balances[_bounty], empty);

    // send 1.5% - to adviser account
    value = safePerc(totalSupply, 150);
    balances[_crowdsale] = safeSub(balances[_crowdsale], value);
    balances[_adviser] = value;
    emit Transfer(_crowdsale, _adviser, balances[_adviser], empty);

    // send 1% - to developer account
    value = safePerc(totalSupply, 100);
    balances[_crowdsale] = safeSub(balances[_crowdsale], value);
    balances[_developer] = value;
    emit Transfer(_crowdsale, _developer, balances[_developer], empty);
  } 

  /**
  * Owner may issue new tokens
  */
  function mint(address _receiver, uint _amount) public onlyOwner {
    balances[_receiver] = safeAdd(balances[_receiver], _amount);
    totalSupply = safeAdd(totalSupply, _amount);
    bytes memory empty;    
    emit Transfer(0x0, _receiver, _amount, empty);    
  }

  /**
  * Owner can update token information here.
  */
  function updateTokenInformation(string _name, string _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;
    emit UpdatedTokenInformation(_name, _symbol);
  }
}