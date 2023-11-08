// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

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

    address private admin;
    uint private registrationTax;
    uint private numberOfProducts;

    mapping (address => bool) registeredProducers;
    mapping (uint => Product) registeredProducts;

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

    function setRegistrationTax(uint newTax) isAdmin payable external {
        require(newTax >= 0, "Registration tax must not be negative");
        
        registrationTax = newTax;

        emit NewRegistrationTax(registrationTax);
    }

    function getRegistrationTax() view external returns (uint) {
        return registrationTax;
    }

    function registerProducer() checkCost(registrationTax) payable external {
        require(registeredProducers[msg.sender] == false, "Producer is already registered");

        registeredProducers[msg.sender] = true;

        emit NewProducer(msg.sender);

        if(msg.value > registrationTax) {
            address payable buyer = payable(msg.sender);

            buyer.transfer(msg.value - registrationTax);

            emit SentChange(msg.sender, msg.value, msg.value - registrationTax);
        }
    }

    function checkRegisteredProducer(address producer) view external returns (bool) {
        return registeredProducers[producer];
    }

    function registerProduct(string memory name, uint volume) registeredProducer(msg.sender) payable external {
        require(volume > 0, "Volume must be positive");

        Product memory product = Product(name, volume, msg.sender);

        registeredProducts[numberOfProducts] = product;

        numberOfProducts++;

        emit NewProduct(numberOfProducts, name);
    }

    function getProductInfo(uint id) registeredProduct(id) view external returns (Product memory) {
        return registeredProducts[id];
    }
}