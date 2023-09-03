// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTAuction is ERC721Holder, Pausable, Ownable, ReentrancyGuard {
    struct Auction {
        IERC721 nftContract;
        uint256[] nftIds;
        address payable seller;
        uint256 startPrice;
        uint256 reservePrice;
        uint256 buyNowPrice;
        address payable highestBidder;
        uint256 highestBid;
        uint256 bidIncrement;
        uint256 endTimestamp;
        bool ended;
    }

    Auction[] public auctions;
    uint256 public auctionFee = 50; // 5%, expressed as parts per 1000
    mapping(address => uint256[]) public sellerAuctions;

    event AuctionCreated(
        uint256 auctionIndex,
        address seller,
        uint256 startPrice,
        uint256 endTimestamp
    );
    event NewBid(uint256 auctionIndex, address bidder, uint256 bidAmount);
    event AuctionEnded(
        uint256 auctionIndex,
        address winner,
        uint256 winningBid
    );
    event AuctionCancelled(uint256 auctionIndex);
    event BuyNow(uint256 auctionIndex, address buyer, uint256 price);

    function createAuction(
        IERC721 _nftContract,
        uint256[] memory _nftIds,
        uint256 _startPrice,
        uint256 _reservePrice,
        uint256 _buyNowPrice,
        uint256 _bidIncrement,
        uint256 _auctionDurationInDays
    ) public whenNotPaused {
        // Add more checks here
        require(_nftIds.length > 0, "No NFTs provided for the auction.");
        require(_startPrice < _buyNowPrice, "Starting price should be less than buy now price.");
        require(_bidIncrement > 0, "Bid increment should be greater than 0.");
        
        // Check ownership and approval
        for (uint256 i = 0; i < _nftIds.length; i++) {
            require(_nftContract.ownerOf(_nftIds[i]) == msg.sender, "You don't own all the NFTs.");
        }

        require(
            _auctionDurationInDays > 0 && _auctionDurationInDays <= 1000,
            "Invalid auction duration."
        );
        uint256 endTimestamp = block.timestamp +
            (_auctionDurationInDays * 1 days);

        for (uint256 i = 0; i < _nftIds.length; i++) {
            _nftContract.safeTransferFrom(
                msg.sender,
                address(this),
                _nftIds[i]
            );
        }

        auctions.push(
            Auction({
                nftContract: _nftContract,
                nftIds: _nftIds,
                seller: payable(msg.sender),
                startPrice: _startPrice,
                reservePrice: _reservePrice,
                buyNowPrice: _buyNowPrice,
                highestBidder: payable(address(0)),
                highestBid: 0,
                bidIncrement: _bidIncrement,
                endTimestamp: endTimestamp,
                ended: false
            })
        );
        uint256 auctionIndex = auctions.length - 1;
        sellerAuctions[msg.sender].push(auctionIndex);

        emit AuctionCreated(
            auctionIndex,
            msg.sender,
            _startPrice,
            endTimestamp
        );
    }

    function bid(uint256 auctionIndex)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        Auction storage auction = auctions[auctionIndex];

        require(
            block.timestamp <= auction.endTimestamp,
            "This auction has ended."
        );
        require(!auction.ended, "This auction has already ended.");
        require(
            msg.value >= auction.startPrice,
            "Your bid is below the starting price."
        );
        require(
            msg.value >= auction.highestBid + auction.bidIncrement,
            "Your bid increment is less than the minimum bid increment."
        );
      

        if (auction.highestBid != 0) {
            (bool success, ) = auction.highestBidder.call{
                value: auction.highestBid
            }("");
            require(success, "Refund failed.");
        }

        auction.highestBidder = payable(msg.sender);
        auction.highestBid = msg.value;

        emit NewBid(auctionIndex, msg.sender, msg.value);
    }

    function buyNow(uint256 auctionIndex)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        Auction storage auction = auctions[auctionIndex];

        require(!auction.ended, "This auction has already ended.");
        require(
            msg.value == auction.buyNowPrice,
            "Sent value must be equal to buy now price."
        );

        auction.ended = true;

        uint256 fee = (auction.buyNowPrice * auctionFee) / 1000;
        uint256 sellerProceeds = auction.buyNowPrice - fee;

        for (uint256 i = 0; i < auction.nftIds.length; i++) {
            auction.nftContract.safeTransferFrom(
                address(this),
                msg.sender,
                auction.nftIds[i]
            );
        }

        (bool success, ) = auction.seller.call{value: sellerProceeds}("");
        require(success, "Transfer of bid to seller failed.");

        (bool feeSuccess, ) = owner().call{value: fee}("");
        require(feeSuccess, "Transfer of fee to owner failed.");

        emit BuyNow(auctionIndex, msg.sender, msg.value);
    }

    function endAuction(uint256 auctionIndex)
        public
        whenNotPaused
        nonReentrant
    {
        Auction storage auction = auctions[auctionIndex];

        require(msg.sender == auction.seller, "You are not the seller.");
        require(!auction.ended, "This auction has already ended.");
        require(
            block.timestamp > auction.endTimestamp,
            "The auction is not over yet."
        );

        auction.ended = true;

        if (auction.highestBid >= auction.reservePrice) {
            uint256 fee = (auction.highestBid * auctionFee) / 1000;
            uint256 sellerProceeds = auction.highestBid - fee;

            for (uint256 i = 0; i < auction.nftIds.length; i++) {
                auction.nftContract.safeTransferFrom(
                    address(this),
                    auction.highestBidder,
                    auction.nftIds[i]
                );
            }

            (bool success, ) = auction.seller.call{value: sellerProceeds}("");
            require(success, "Transfer of bid to seller failed.");

            (bool feeSuccess, ) = owner().call{value: fee}("");
            require(feeSuccess, "Transfer of fee to owner failed.");

            emit AuctionEnded(
                auctionIndex,
                auction.highestBidder,
                auction.highestBid
            );
        } else {
            for (uint256 i = 0; i < auction.nftIds.length; i++) {
                auction.nftContract.safeTransferFrom(
                    address(this),
                    auction.seller,
                    auction.nftIds[i]
                );
            }

            emit AuctionEnded(auctionIndex, address(0), 0);
        }
    }

    function cancelAuction(uint256 auctionIndex)
        public
        whenNotPaused
        nonReentrant
    {
        Auction storage auction = auctions[auctionIndex];

        require(msg.sender == auction.seller, "You are not the seller.");
        require(!auction.ended, "This auction has already ended.");

        auction.ended = true;

        if (auction.highestBid > 0) {
            (bool success, ) = auction.highestBidder.call{
                value: auction.highestBid
            }("");
            require(success, "Refund failed.");
        }

        for (uint256 i = 0; i < auction.nftIds.length; i++) {
            auction.nftContract.safeTransferFrom(
                address(this),
                auction.seller,
                auction.nftIds[i]
            );
        }

        emit AuctionCancelled(auctionIndex);
    }

    function getAllAuctions()
        public
        view
        returns (uint256[] memory, Auction[] memory)
    {
        uint256[] memory auctionIndexes = new uint256[](auctions.length);
        Auction[] memory allAuctions = new Auction[](auctions.length);

        for (uint256 i = 0; i < auctions.length; i++) {
            auctionIndexes[i] = i;
            allAuctions[i] = auctions[i];
        }

        return (auctionIndexes, allAuctions);
    }

    function setAuctionFee(uint256 _auctionFee) public onlyOwner {
        require(_auctionFee <= 1000, "Auction fee should not exceed 100%");
        auctionFee = _auctionFee;
    }

   function myAuctions() public view returns (Auction[] memory, uint256[] memory) {
    uint256[] memory ownedAuctionIndexes = sellerAuctions[msg.sender];
    uint256 activeAuctionCount = 0;

    // Count the number of active auctions
    for (uint256 i = 0; i < ownedAuctionIndexes.length; i++) {
        if (!auctions[ownedAuctionIndexes[i]].ended) {
            activeAuctionCount++;
        }
    }

    Auction[] memory activeAuctions = new Auction[](activeAuctionCount);
    uint256[] memory activeAuctionIndexes = new uint256[](activeAuctionCount);
    uint256 activeAuctionIndex = 0;
    
    // Add active auctions and their indexes to the return arrays
    for (uint256 i = 0; i < ownedAuctionIndexes.length; i++) {
        if (!auctions[ownedAuctionIndexes[i]].ended) {
            activeAuctions[activeAuctionIndex] = auctions[ownedAuctionIndexes[i]];
            activeAuctionIndexes[activeAuctionIndex] = ownedAuctionIndexes[i];
            activeAuctionIndex++;
        }
    }

    return (activeAuctions, activeAuctionIndexes);
}


function hasAuctionEnded(uint256 auctionIndex) public view returns (bool) {
    return auctions[auctionIndex].ended;
}


    function emergencyWithdrawTokens(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "No token balance to withdraw");
        _token.transfer(msg.sender, balance);
    }

    function emergencyWithdrawNFTs(IERC721 _nftContract, uint256 _nftId) external onlyOwner {
        require(_nftContract.ownerOf(_nftId) == address(this), "Contract does not own this NFT");
        _nftContract.safeTransferFrom(address(this), msg.sender, _nftId);
    }


}
