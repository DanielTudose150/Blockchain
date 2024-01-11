// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

import './ProductIdentification.sol';
import './ProductStore.sol';

contract ProductDeposit {
    event NewVolumeTax(uint tax);
    event NewMaxVolume(uint maxVolume);
    event NewStore(address store);
    event ProductQuantityChanged(uint id, uint newQuantity);
    event SentChange(address receiver, uint received, uint change);

    struct DepositedProduct {
        uint volume;
        uint quantity;
        bool initialized;
    }

    address private thisContract;

    address private admin;
    uint private volumeTax;
    uint private maxVolume;
    uint private usedVolume;

    mapping (uint => DepositedProduct) depositedProducts;
    mapping (address => bool) registeredStores;
    mapping (address => ProductIdentification) storeIdentification;
    mapping (address => address) piFromStore;

    constructor () {
        admin = msg.sender;
        volumeTax = 0;
        maxVolume = 0;
        usedVolume = 0;
        thisContract = address(this);
    }

    modifier isAdmin() {
        require(msg.sender == admin, "You are not allowed to set the registration tax | PD");
        _;
    }

    modifier isStore() {
        require(registeredStores[msg.sender], "Store not registered. | PD");
        _;
    }

    function setVolumeTax(uint newTax) isAdmin() payable external {
        require(newTax >= 0, "Registration tax must not be negative | PD");

        emit NewVolumeTax(newTax);

        volumeTax = newTax;
    }

    function getVolumeTax() view external returns (uint) {
        return volumeTax;
    }

    function setMaxVolume(uint newMaxVolume) isAdmin() payable external {
        require(newMaxVolume >= 0, "Max volume must not be negative | PD");

        emit NewMaxVolume(newMaxVolume);

        maxVolume = newMaxVolume;
    }

    function getMaxVolume() view external returns (uint) {
        return maxVolume;
    }

    function depositProduct(uint tokens, uint productID, uint quantity, address client) isStore payable external {
        require(quantity >= 0, "Quantity must be a positive number. | PD");

        bool deposited = false;
        uint volume;

        deposited = depositedProducts[productID].initialized;
        if (!deposited) {
            volume = storeIdentification[msg.sender].getProductInfo(productID).volume;
        }
        else {
            volume = depositedProducts[productID].volume;
        }

        uint totalVolume = volume * quantity;
        
        require(maxVolume - usedVolume >= totalVolume, "Not enough space left in deposit | PD");
        require(tokens <= storeIdentification[msg.sender].sampleCoin().balanceOf(client), "Not enough balance. | PD");
        require(tokens >= totalVolume * volumeTax, "Not enough currency sent | PD");
        //require(msg.value >= totalVolume * volumeTax, "Not enough currency sent");
        //require(storeIdentification[msg.sender].sampleCoin().balanceOf(client) >= totalVolume * volumeTax, "Not enough currency sent");
        //require(storeIdentification[msg.sender].sampleCoin().transferFrom(client,  thisContract,  totalVolume * volumeTax), "Not enough currency.");
        
        emit ProductQuantityChanged(productID, depositedProducts[productID].quantity);

        storeIdentification[msg.sender].sampleCoin().transferFrom(client, piFromStore[msg.sender], totalVolume * volumeTax);

        if(tokens != totalVolume * volumeTax) {
            //address payable buyer = payable(client);

            emit SentChange(msg.sender, msg.value, tokens - totalVolume * volumeTax);

            //buyer.transfer(msg.value - totalVolume * volumeTax);
            //storeIdentification[msg.sender].sampleCoin().transferFrom(piFromStore[msg.sender], client, tokens - totalVolume * volumeTax);
            storeIdentification[msg.sender].sampleCoin().transfer(client, tokens - totalVolume * volumeTax);
        }
        
        if (!deposited) {
            depositedProducts[productID] = DepositedProduct(volume, quantity, true);
        }
        else {
            depositedProducts[productID].quantity += quantity;
        }

        usedVolume += totalVolume;
    }

    function withdrawProduct(uint productID, uint quantity) isStore payable external {
        require(depositedProducts[productID].initialized, "Product not in deposit. | PD");
        require(depositedProducts[productID].quantity >= quantity, "Not enough quantity in deposit. | PD");

        emit ProductQuantityChanged(productID, depositedProducts[productID].quantity - quantity);

        depositedProducts[productID].quantity -= quantity;
        
        usedVolume -= depositedProducts[productID].volume * quantity;
    }

    function registerStore(address storeAddr) payable external {
        emit NewStore(storeAddr);

        ProductStore store = ProductStore(storeAddr);

        registeredStores[storeAddr] = true;

        storeIdentification[storeAddr] = ProductIdentification(store.getProductIdentificationAddress());
        piFromStore[storeAddr] = store.getProductIdentificationAddress();
    }
}