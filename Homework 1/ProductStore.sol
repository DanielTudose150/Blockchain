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
    SampleToken private sampleCoin;

    address private thisContract;
    address private admin;
    address private depositAddress;
    address private productIdentificationAddress;

    mapping (uint => MinimumProduct) productsInStore;

    constructor() {
        admin = msg.sender;
        depositAddress = address(0);
        productIdentificationAddress = address(0);
        thisContract = address(this);
    }


    modifier isAdmin() {
        require(msg.sender == admin, "You are not admin. | PS");
        _;
    }

    modifier isDeposit() {
        require(msg.sender == depositAddress, "Not the registered deposit. | PS");
        _;
    }

    function setDepositAddress(address _deposit) isAdmin external {
        require(_deposit != address(0), "Invalid address. | PS");

        emit DepositAddressSet(_deposit);

        depositAddress = _deposit;
        
        deposit = ProductDeposit(depositAddress);        
    }

    function setProductIdentificationAddress(address pi) isAdmin external {
        require(pi != address(0), "Invalid address. | PS");

        emit ProductIdentificationAddressSet(pi);

        productIdentificationAddress = pi;

        productIdentification = ProductIdentification(pi);

        sampleCoin = SampleToken(productIdentification.sampleCoinAddress());
    }

    function getProductIdentificationAddress() isDeposit external view returns (address) {
        return productIdentificationAddress;
    }

    function setDepositAndPIAddress(address _deposit, address pi) isAdmin external {
        require(_deposit != address(0), "Invalid address. | PS");
        require(pi != address(0), "Invalid address. | PS");

        emit DepositAddressSet(_deposit);

        depositAddress = _deposit;

        deposit = ProductDeposit(_deposit);

        emit ProductIdentificationAddressSet(pi);
        
        productIdentificationAddress = pi;
        
        productIdentification = ProductIdentification(pi);

        sampleCoin = SampleToken(productIdentification.sampleCoinAddress());
    }

    function addProduct(uint productID, uint quantity) isAdmin external {
        if(productsInStore[productID].initialized == false) {
            MinimumProduct memory product = MinimumProduct(0, 0, true);
            productsInStore[productID] = product;
        }

        emit ProductAdded(productID, quantity);

        deposit.withdrawProduct(productID, quantity);

        productsInStore[productID].quantity = quantity;
    }

    function setPrice(uint productID, uint newPrice) isAdmin external {
        require(productsInStore[productID].initialized, "Product not in store. | PS");
        require(newPrice >= 0, "Price must be a positive number. | PS");

        emit NewPriceSet(productID, newPrice);

        productsInStore[productID].price = newPrice;
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
        require(productsInStore[id].initialized, "Product is not available. | PS");

        return productsInStore[id].price;
    }
    
    function BuyProduct(uint tokens, uint productID, uint quantity) external payable {
        require(productsInStore[productID].initialized, "Product not in store. | PS");
        require(productsInStore[productID].quantity >= quantity, "Not enough products in store. | PS");
        require(productsInStore[productID].price * quantity <= tokens, "Not enough currency. | PS");

        uint totalPrice = quantity * productsInStore[productID].price;

        sampleCoin.transferFrom(msg.sender, thisContract, tokens);

        if(totalPrice != tokens) {
            //address payable buyer = payable(msg.sender);

            emit SentChange(totalPrice, msg.value, tokens - totalPrice);

            //buyer.transfer(msg.value - totalPrice);
            //sampleCoin.transferFrom(productIdentificationAddress, msg.sender, tokens - totalPrice);
            sampleCoin.transfer(msg.sender, tokens - totalPrice);
        }

        ProductIdentification.Product memory product = productIdentification.getProductInfo(productID);

        // address payable producer = payable(product.producer);
        address producer = product.producer;

        emit SentToProducer(producer, totalPrice / 2, totalPrice);

        //producer.transfer(totalPrice / 2);
        //sampleCoin.transferFrom(productIdentificationAddress, producer, totalPrice / 2);
        sampleCoin.transfer(producer, totalPrice / 2);
        sampleCoin.transfer(productIdentificationAddress, totalPrice - totalPrice / 2);

        emit ProductSold(productID, quantity);
        
        productsInStore[productID].quantity -= quantity;
    }

    function depositProduct(uint tokens, uint productID, uint quantity) isAdmin external payable {
        require(tokens >= deposit.getVolumeTax() * quantity, "Not enough currency. | PS");
        require(tokens <= sampleCoin.balanceOf(msg.sender), "Not enough balance | PS");

        deposit.depositProduct(tokens, productID, quantity, msg.sender);
    }
}