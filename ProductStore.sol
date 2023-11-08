// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

import './ProductIdentification.sol';
import './ProductDeposit.sol';

contract ProductStore {
    event DepositAddressSet(address deposit);
    event ProductIdentificationAddressSet(address identification);
    event ProductAdded(uint id, uint quantity);
    event NewPriceSet(uint id, uint price);
    event ProductSold(uint id, uint quantity);
    event SentChange(uint total, uint received, uint sent);
    event SentToProducer(address producer, uint sent, uint total);

    struct MinimumProduct {
        uint price;
        uint quantity;
        bool initialized;
    }

    ProductIdentification private productIdentification;
    ProductDeposit private deposit;

    address private admin;
    address private depositAddress;
    address private productIdentificationAddress;

    mapping (uint => MinimumProduct) productsInStore;

    constructor() {
        admin = msg.sender;
        depositAddress = address(0);
        productIdentificationAddress = address(0);
    }


    modifier isAdmin() {
        require(msg.sender == admin, "You are not admin.");
        _;
    }

    modifier isDeposit() {
        require(msg.sender == depositAddress, "Not the registered deposit.");
        _;
    }

    function setDepositAddress(address _deposit) isAdmin external {
        require(_deposit != address(0), "Invalid address.");

        depositAddress = _deposit;
        
        deposit = ProductDeposit(depositAddress);

        emit DepositAddressSet(depositAddress);
    }

    function setProductIdentificationAddress(address pi) isAdmin external {
        require(pi != address(0), "Invalid address.");

        productIdentificationAddress = pi;

        productIdentification = ProductIdentification(pi);

        emit ProductIdentificationAddressSet(pi);
    }

    function getProductIdentificationAddress() isDeposit external view returns (address) {
        return productIdentificationAddress;
    }

    function setDepositAndPIAddress(address _deposit, address pi) isAdmin external {
        require(_deposit != address(0), "Invalid address.");
        require(pi != address(0), "Invalid address.");

        depositAddress = _deposit;

        deposit = ProductDeposit(_deposit);

        emit DepositAddressSet(_deposit);

        productIdentificationAddress = pi;
        
        productIdentification = ProductIdentification(pi);

        emit ProductIdentificationAddressSet(pi);
    }

    function addProduct(uint productID, uint quantity) isAdmin external {
        if(productsInStore[productID].initialized == false) {
            MinimumProduct memory product = MinimumProduct(0, 0, true);
            productsInStore[productID] = product;
        }

        deposit.withdrawProduct(productID, quantity);

        productsInStore[productID].quantity = quantity;

        emit ProductAdded(productID, quantity);
    }

    function setPrice(uint productID, uint newPrice) isAdmin external {
        require(productsInStore[productID].initialized, "Product not in store.");
        require(newPrice >= 0, "Price must be a positive number.");

        productsInStore[productID].price = newPrice;

        emit NewPriceSet(productID, newPrice);
    }

    function checkAvailability(uint id) external view returns (uint) {
        // Can also be made to use a "require"
        // require(productsInStore[id].initialized, "Cannot check availability for an unregistered product!");
        if(!productsInStore[id].initialized) {
            return 0;
        }

        return productsInStore[id].quantity;
    }

    function checkPrice(uint id) external view returns (uint) {
        require(productsInStore[id].initialized, "Product is not available.");

        return productsInStore[id].price;
    }
    
    function BuyProduct(uint productID, uint quantity) external payable {
        require(productsInStore[productID].initialized, "Product not in store.");
        require(productsInStore[productID].quantity >= quantity, "Not enough products in store.");
        require(productsInStore[productID].price * quantity <= msg.value, "Not enough currency.");

        uint totalPrice = quantity * productsInStore[productID].price;

        if(totalPrice != msg.value) {
            address payable buyer = payable(msg.sender);

            buyer.transfer(msg.value - totalPrice);

            emit SentChange(totalPrice, msg.value, msg.value - totalPrice);
        }

        ProductIdentification.Product memory product = productIdentification.getProductInfo(productID);

        address payable producer = payable(product.producer);

        producer.transfer(totalPrice / 2);

        emit SentToProducer(producer, totalPrice / 2, totalPrice);

        productsInStore[productID].quantity -= quantity;

        emit ProductSold(productID, quantity);
    }

    function depositProduct(uint productID, uint quantity) isAdmin external payable {
        require(msg.value >= deposit.getVolumeTax() * quantity, "Not enough currency.");

        deposit.depositProduct{value: msg.value}(productID, quantity, msg.sender);
    }
}