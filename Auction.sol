// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Auction {

    address payable public beneficiary;
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) public deposits;
    address[] public bidders;

    bool public auctionEnded;
    uint public constant COMMISSION_PERCENTAGE = 2;

    event NewBid(address indexed bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event PartialRefund(address indexed bidder, uint amount);

    modifier onlyWhileAuctionIsActive() {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        _;
    }

    modifier onlyAfterAuctionHasEnded() {
        require(block.timestamp >= auctionEndTime, "Auction is still active.");
        _;
    }

    modifier notOwner() {
        require(msg.sender != beneficiary, "The beneficiary cannot bid.");
        _;
    }

    constructor(uint _biddingTime, address payable _beneficiary) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid() external payable notOwner onlyWhileAuctionIsActive {
        uint currentBid = deposits[msg.sender] + msg.value;
        require(currentBid > highestBid, "You must bid a higher amount.");

        if (highestBid > 0) {
            uint requiredIncrease = (highestBid * 5) / 100;
            require(currentBid >= highestBid + requiredIncrease, "Bid must be at least 5% higher than the current highest bid.");
        }

        if (deposits[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        deposits[msg.sender] = currentBid;

        if (currentBid > highestBid) {
            highestBidder = msg.sender;
            highestBid = currentBid;
        }

        if (auctionEndTime - block.timestamp < 10 minutes) {
            auctionEndTime += 10 minutes;
        }

        emit NewBid(msg.sender, currentBid);
    }

    function withdrawPartial() external {
        uint amountToWithdraw = deposits[msg.sender] - highestBid;
        require(amountToWithdraw > 0, "No funds available for partial withdrawal.");
        
        deposits[msg.sender] -= amountToWithdraw;
        payable(msg.sender).transfer(amountToWithdraw);

        emit PartialRefund(msg.sender, amountToWithdraw);
    }

    function endAuction() external onlyAfterAuctionHasEnded {
        require(!auctionEnded, "The auction has already been officially ended.");
        auctionEnded = true;

        uint commission = (highestBid * COMMISSION_PERCENTAGE) / 100;
        uint amountToTransfer = highestBid - commission;

        beneficiary.transfer(amountToTransfer);

        emit AuctionEnded(highestBidder, highestBid);
    }

    function refundNonWinners() external {
        require(auctionEnded, "The auction must be officially ended to claim refunds.");

        for (uint i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];
            if (bidder != highestBidder) {
                uint amount = deposits[bidder];
                if (amount > 0) {
                    deposits[bidder] = 0;
                    payable(bidder).transfer(amount);
                }
            }
        }
    }

    function getWinner() external view returns (address, uint) {
        return (highestBidder, highestBid);
    }

    function getBids() external view returns (address[] memory, uint[] memory) {
        uint bidderCount = bidders.length;
        address[] memory bidderAddresses = new address[](bidderCount);
        uint[] memory bidAmounts = new uint[](bidderCount);

        for (uint i = 0; i < bidderCount; i++) {
            bidderAddresses[i] = bidders[i];
            bidAmounts[i] = deposits[bidders[i]];
        }

        return (bidderAddresses, bidAmounts);
    }
}