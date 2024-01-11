// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.21;

import './ProductIdentification.sol';
import './SampleCoin.sol';

contract Auction {
    
    address payable internal auction_owner;
    uint256 public auction_start;
    uint256 public auction_end;
    uint256 public highestBid;
    address public highestBidder;
 

    enum auction_state {
        CANCELLED, STARTED
    }

    struct car {
        string  Brand;
        string  Rnumber;
    }
    
    car public Mycar;
    address[] bidders;

    // How much each person bid.
    mapping(address => uint) public bids;

    auction_state public STATE;


    modifier an_ongoing_auction() {
        require(block.timestamp <= auction_end && STATE == auction_state.STARTED);
        _;
    }
    
    modifier only_owner() {
        require(msg.sender == auction_owner);
        _;
    }
    
    function bid() public virtual payable returns (bool) {}
    function withdraw() public virtual returns (bool) {}
    function cancel_auction() external virtual returns (bool) {}
    
    event BidEvent(address indexed highestBidder, uint256 highestBid);
    event WithdrawalEvent(address withdrawer, uint256 amount);
    event CanceledEvent(string message, uint256 time);  
    
}

contract MyAuction is Auction {
    
    ProductIdentification public productIdentification;
    SampleToken currency;

    constructor (uint _biddingTime, address payable _owner, string memory _brand, string memory _Rnumber, address pi, address money) {
        
        productIdentification = ProductIdentification(pi);
        currency = SampleToken(money);

        require(productIdentification.isProductNameRegistered(_brand), "The car brand is not registered!");
        
        auction_owner = _owner;
        auction_start = block.timestamp;
        auction_end = auction_start + _biddingTime*1 hours;
        STATE = auction_state.STARTED;
        Mycar.Brand = _brand;
        Mycar.Rnumber = _Rnumber;
    } 
    
    function get_owner() public view returns(address) {
        return auction_owner;
    }
    
    fallback () external payable {
        // Return all money in case Ether is send.
        payable(msg.sender).transfer(msg.value);
    }
    
    receive () external payable {
        // Return all money in case Ether is send.
        payable(msg.sender).transfer(msg.value);
    }
    
    function bid(uint bidAmount) public payable an_ongoing_auction returns (bool) {
        
        // require(bids[msg.sender] + msg.value > highestBid, "You can't bid, Make a higher Bid");
        require(auction_owner != msg.sender, "Owner cannot bid.");
        require(bids[msg.sender] == 0, "Already registered, cannot bid twice!");
        require(bidAmount + bids[msg.sender] > highestBid, "You can't bid, Make a higher Bid");
        require(currency.transferFrom(msg.sender, address(this), bidAmount), "Current transfer failed!");

        highestBidder = msg.sender;
        highestBid = bids[msg.sender] + bidAmount;
        bidders.push(msg.sender);
        bids[msg.sender] = highestBid;

        emit BidEvent(highestBidder,  highestBid);

        return true;
    } 
    
    function cancel_auction() external only_owner an_ongoing_auction override returns (bool) {
    
        STATE = auction_state.CANCELLED;
        emit CanceledEvent("Auction Cancelled", block.timestamp);
        return true;
    }
    
    function withdraw() public override returns (bool) {
        
        // The owner cannot withdraw money from the action, BUT he can destruct the action and get the money.
        // require(auction_owner != msg.sender, "As owner, you need to close the action before you can withdraw your money.");
        require(block.timestamp > auction_end || STATE == auction_state.CANCELLED, "You can't withdraw, the auction is still open");
        
        // The highest bidder cannot withdraw his money.
        require(msg.sender != highestBidder, "You cannot withdraw your money. You won the auction!");

        uint amount;
        address returnTo;
        if (msg.sender == auction_owner) {
            require(bids[bidders[bidders.length-1]] != 0, "The owner already withdrew the money!");
            amount = highestBid;
            bids[bidders[bidders.length-1]] = 0;
            returnTo = auction_owner;
        }
        else {
            require(bids[msg.sender] != 0, "You cannot withdraw your money twice!");
            amount = bids[msg.sender];
            bids[msg.sender] = 0;
            returnTo = msg.sender;
        }


        // payable(msg.sender).transfer(amount);
        require(currency.transfer(returnTo, amount), "Failed to withdraw money!");

        emit WithdrawalEvent(returnTo, amount);
        return true;
      
    }
    
    function destruct_auction() external only_owner returns (bool) {
        
        require(block.timestamp > auction_end || STATE == auction_state.CANCELLED,"You can't destruct the contract,The auction is still open");

        // Take the money from the highest bidder and transfer it to the owner
        // if they did not already took it.
        if (bids[bidders[bidders.length-1]] != 0) {
            currency.transfer(auction_owner, highestBid);
            bids[bidders[bidders.length-1]] = 0; // Mark this action.
        }

        for(uint i = 0; i < bidders.length; i++)
        {   
            // If they did not already withdrawn their money, automatically return it.
            if (bids[bidders[i]] != 0) {
                currency.transfer(bidders[i], bids[bidders[i]]);
                bids[bidders[i]] = 0;
            }
        }

        selfdestruct(auction_owner);
        return true;
    
    } 
}


