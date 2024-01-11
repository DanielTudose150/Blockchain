// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

import './SampleCoin.sol';

contract ProductIdentification {
    event NewRegistrationTax(uint tax);
    event NewProducer(address producer);
    event NewProduct(uint quantity, string name);
    event SentChange(address receiver, uint received, uint change);

    struct Product {
        string name;
        uint volume;
        address producer;
    }

    SampleToken public sampleCoin;

    address public sampleCoinAddress;

    address private admin;
    uint private registrationTax;
    uint private numberOfProducts;

    mapping (address => uint) public producerBalances;

    mapping (address => bool) registeredProducers;
    mapping (uint => Product) registeredProducts;
    mapping (string => bool) registeredProductsByName;  // Used in MyAction contract

    constructor () {
        admin = msg.sender;
        registrationTax = 0;
        numberOfProducts = 0;
    }

    modifier isAdmin() {
        require(msg.sender == admin, "You are not allowed to set the registration tax");
        _;
    }

    modifier checkCost(uint cost) {
        require(msg.value >= cost, "Not enough currency sent");
        _;
    }

    modifier registeredProducer(address producer) {
        require(registeredProducers[producer], "Producer is not registered");
        _;
    }

    modifier registeredProduct(uint id) {
        require(id < numberOfProducts, "Product is not registered");
        _;
    }

    modifier onlySampleCoin() {
        require(msg.sender == sampleCoinAddress);
        _;
    }

    function setSampleCoinContract(address _sampleCoinAddress) external isAdmin {
        sampleCoinAddress = _sampleCoinAddress;
        sampleCoin = SampleToken(sampleCoinAddress);
    }
    
    function setRegistrationTax(uint newTax) isAdmin payable external {
        require(newTax >= 0, "Registration tax must not be negative");
        
        emit NewRegistrationTax(newTax);

        registrationTax = newTax;
    }

    function getRegistrationTax() view external returns (uint) {
        return registrationTax;
    }

    /*function registerProducer() checkCost(registrationTax) payable external {
        require(registeredProducers[msg.sender] == false, "Producer is already registered");

        emit NewProducer(msg.sender);

        registeredProducers[msg.sender] = true;

        if(msg.value > registrationTax) {
            address payable buyer = payable(msg.sender);

            emit SentChange(msg.sender, msg.value, msg.value - registrationTax);

            buyer.transfer(msg.value - registrationTax);
        }
    }*/

    function registerProducer() payable external {
        require(sampleCoin.balanceOf(msg.sender) >= registrationTax, "Insufficient SampleCoin balance.");

        emit NewProducer(msg.sender);

        registeredProducers[msg.sender] = true;

        // uint excessAmount = sampleCoin.balanceOf(msg.sender) - registrationTax;
        
        sampleCoin.transferFrom(msg.sender, address(this), registrationTax);

        /*
        if (excessAmount > 0) {
            emit SentChange(msg.sender, sampleCoin.balanceOf(msg.sender), excessAmount);

            sampleCoin.transfer(msg.sender, excessAmount);
        }

        producerBalances[msg.sender] += registrationTax;
        */
    }

    function checkRegisteredProducer(address producer) view external returns (bool) {
        return registeredProducers[producer];
    }

    function registerProduct(string memory name, uint volume) registeredProducer(msg.sender) payable external {
        require(volume > 0, "Volume must be positive");

        emit NewProduct(numberOfProducts + 1, name);

        Product memory product = Product(name, volume, msg.sender);

        registeredProducts[numberOfProducts] = product;
        registeredProductsByName[name] = true;

        numberOfProducts++;
    }

    function getProductInfo(uint id) registeredProduct(id) view external returns (Product memory) {
        return registeredProducts[id];
    }

    function isProductNameRegistered(string memory productName) view external returns (bool) {
        return registeredProductsByName[productName];
    }

    function retrieveCurrency() isAdmin external payable {
        sampleCoin.transfer(msg.sender, sampleCoin.balanceOf(address(this)));
    }
}