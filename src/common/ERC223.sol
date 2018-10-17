pragma solidity ^0.4.24;

import './Agent.sol';
import './SafeMath.sol';
import './ERC223I.sol';

/**
 * @title Standard ERC223 token
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223 is ERC223I, Agent, SafeMath {

  mapping(address => uint) balances;
  
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  address public crowdsale = address(0);
  bool public released = false;

  /**
   * @dev Limit token transfer until the crowdsale is over.
   */
  modifier canTransfer() {
    assert(released || msg.sender == crowdsale);
    _;
  }

  modifier onlyCrowdsaleContract() {
    assert(msg.sender == crowdsale);
    _;
  }  
  
  function name() public view returns (string _name) {
    return name;
  }

  function symbol() public view returns (string _symbol) {
    return symbol;
  }

  function decimals() public view returns (uint8 _decimals) {
    return decimals;
  }

  function totalSupply() public view returns (uint256 _totalSupply) {
    return totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }  

  // if bytecode exists then the _addr is a contract.
  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
      //retrieve the size of the code on target address, this needs assembly
      length := extcodesize(_addr)
    }
    return (length>0);
  }
  
  // function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) external canTransfer() returns (bool success) {      
    if(isContract(_to)) {
      return transferToContract(_to, _value, _data);
    } else {
      return transferToAddress(_to, _value, _data);
    }
  }
  
  // standard function transfer similar to ERC20 transfer with no _data.
  // added due to backwards compatibility reasons.
  function transfer(address _to, uint _value) external canTransfer() returns (bool success) {      
    bytes memory empty;
    if(isContract(_to)) {
      return transferToContract(_to, _value, empty);
    } else {
      return transferToAddress(_to, _value, empty);
    }
  }

  // function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
  // function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    assert(_to.call.value(0)(abi.encodeWithSignature("tokenFallback(address,uint256,bytes)", msg.sender, _value, _data)));
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  // function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) external canTransfer() returns (bool success) {      
    if(isContract(_to)) {
      if (balanceOf(msg.sender) < _value) revert();
      balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
      balances[_to] = safeAdd(balanceOf(_to), _value);      
      assert(_to.call.value(0)(abi.encodeWithSignature(_custom_fallback), msg.sender, _value, _data));    
      emit Transfer(msg.sender, _to, _value, _data);
      return true;
    } else {
      return transferToAddress(_to, _value, _data);
    }
  }

  function setCrowdsaleContract(address _contract) external onlyOwner {
    crowdsale = _contract;
  }

  /**
   * @dev One way function to release the tokens to the wild. Can be called only from the crowdsale contract.
   */
  function releaseTokenTransfer() external onlyCrowdsaleContract {
    released = true;
  }
}