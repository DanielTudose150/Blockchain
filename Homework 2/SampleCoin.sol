// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SampleToken {
    
    string public name = "Sample Token";
    string public symbol = "TOK";

    uint256 public totalSupply;
    
    event Transfer(address indexed _from,
                   address indexed _to,
                   uint256 _value);

    event Approval(address indexed _owner,
                   address indexed _spender,
                   uint256 _value);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    constructor (uint256 _initialSupply) {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");

        emit Transfer(msg.sender, _to, _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        emit Approval(msg.sender, _spender, _value);
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "Not enough balance.");
        require(_value <= allowance[_from][msg.sender], "Not enough currency in allowance.");

        emit Transfer(_from, _to, _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        return true;
    }
}

contract SampleTokenSale {
    
    SampleToken public tokenContract;
    uint256 public tokenPrice;
    address owner;

    uint256 public tokensSold;

    event Sell(address indexed _buyer, uint256 indexed _amount);

    constructor(SampleToken _tokenContract, uint256 _tokenPrice) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    // Sell msg.sender some tokens
    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value >= _numberOfTokens * tokenPrice, "Not enough currency for acquiring tokens.");
        require(tokenContract.balanceOf(owner) >= _numberOfTokens, "Not enough tokens to be sold.");
        require(tokenContract.allowance(owner, address(this)) >= _numberOfTokens, "Not enough tokens allowed to be sold.");  // The owner should have allowed this contract to sell enough coins through them
        require(tokenContract.transferFrom(owner, msg.sender, _numberOfTokens), "Transfer failed.");

        emit Sell(msg.sender, _numberOfTokens);
        tokensSold += _numberOfTokens;

        if (msg.value > _numberOfTokens * tokenPrice) {
            // Send back any excess money
            payable(msg.sender).transfer(msg.value - _numberOfTokens * tokenPrice);
        }
    }

    // Stop selling tokens
    function endSale() public {
        require(msg.sender == owner, "Not owner.");
        // require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));  // Not needed, the contract no longer holds tokens, only the owner does
        payable(msg.sender).transfer(address(this).balance);
    }

    // Set a new price
    function modifyPrice(uint256 newPrice) public {
        require(msg.sender == owner, "Not owner.");
        require(newPrice >= 0, "New price should be a strictly positive number.");
        tokenPrice = newPrice;
    }
}