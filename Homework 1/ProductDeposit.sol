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

    address private admin;
    uint private volumeTax;
    uint private maxVolume;
    uint private usedVolume;

    mapping (uint => DepositedProduct) depositedProducts;
    mapping (address => bool) registeredStores;
    mapping (address => ProductIdentification) storeIdentification;

    constructor () {
        admin = msg.sender;
        volumeTax = 0;
        maxVolume = 0;
        usedVolume = 0;

    }

    modifier isAdmin() {
        require(msg.sender == admin, "You are not allowed to set the registration tax");
        _;
    }

    modifier isStore() {
        require(registeredStores[msg.sender], "Store not registered.");
        _;
    }

    function setVolumeTax(uint newTax) isAdmin() payable external {
        require(newTax >= 0, "Registration tax must not be negative");

        volumeTax = newTax;

        emit NewVolumeTax(volumeTax);
    }

    function getVolumeTax() view external returns (uint) {
        return volumeTax;
    }

    function setMaxVolume(uint newMaxVolume) isAdmin() payable external {
        require(newMaxVolume >= 0, "Max volume must not be negative");

        maxVolume = newMaxVolume;

        emit NewMaxVolume(newMaxVolume);
    }

    function getMaxVolume() view external returns (uint) {
        return maxVolume;
    }

    function depositProduct(uint productID, uint quantity, address client) isStore payable external {
        require(quantity >= 0, "Quantity must be a positive number.");

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
        
        require(maxVolume - usedVolume >= totalVolume, "Not enough space left in deposit");
        require(msg.value >= totalVolume * volumeTax, "Not enough currency sent");

        if(msg.value != totalVolume * volumeTax) {
            address payable buyer = payable(client);

            buyer.transfer(msg.value - totalVolume * volumeTax);

            emit SentChange(msg.sender, msg.value, msg.value - totalVolume * volumeTax);
        }
        
        if (!deposited) {
            depositedProducts[productID] = DepositedProduct(volume, quantity, true);
        }
        else {
            depositedProducts[productID].quantity += quantity;
        }

        usedVolume += totalVolume;

        emit ProductQuantityChanged(productID, depositedProducts[productID].quantity);
    }

    function withdrawProduct(uint productID, uint quantity) isStore payable external {
        require(depositedProducts[productID].initialized, "Product not in deposit.");
        require(depositedProducts[productID].quantity >= quantity, "Not enough quantity in deposit.");

        depositedProducts[productID].quantity -= quantity;
        
        usedVolume -= depositedProducts[productID].volume * quantity;

        emit ProductQuantityChanged(productID, depositedProducts[productID].quantity);
    }

    function registerStore(address storeAddr) payable external {
        ProductStore store = ProductStore(storeAddr);

        registeredStores[storeAddr] = true;

        storeIdentification[storeAddr] = ProductIdentification(store.getProductIdentificationAddress());

        emit NewStore(storeAddr);
    }
}