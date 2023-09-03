// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarketplace is ReentrancyGuard, Ownable {
    struct Listing {
        address contractAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct Collection {
        uint256 collectionId; // Added collection ID
        string name;
        string logoIPFS;
        string bannerIPFS;
        string description;
        string category;
        address owner;
        bool isHidden;
    }

    struct Token {
        address contractAddress;
        uint256 tokenId;
    }
    struct TokenDetails {
        address contractAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
    }

    event TokenBought(
        uint256 indexed tokenId,
        uint256 royalty,
        address indexed recipient
    );

    event CollectionCreated(
        uint256 indexed collectionId,
        address indexed owner,
        string name
    );

    modifier onlyTokenOwner(address contractAddress, uint256 tokenId) {
        ERC721 tokenContract = ERC721(contractAddress);
        require(
            tokenContract.ownerOf(tokenId) == msg.sender,
            "Only token owner can perform this action"
        );
        _;
    }

    ERC721 public nftToken;
    Token[] public activeListings;
    mapping(address => mapping(uint256 => uint256)) private listingIndex;
    mapping(address => mapping(uint256 => Listing)) public listings;

    uint256 private constant BATCH_PROCESS_LIMIT = 50;
    uint256 public listingFee = 0.01 ether;
    uint256 public totalCollections;
    uint256 public collectionCount = 0;
    mapping(uint256 => Token[]) public collectionTokens;
    mapping(uint256 => Collection) public collections;
    mapping(address => mapping(uint256 => bool))
        private isTokenAddedToCollection;
    mapping(address => mapping(uint256 => bool)) private isTokenSold;
    mapping(address => mapping(uint256 => uint256)) private highestSoldPrice;

    event TokenListed(
        uint256 indexed tokenId,
        uint256 price,
        address indexed seller
    );
    event TokenSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer
    );
    event SaleCancelled(uint256 indexed tokenId, address indexed seller);

    constructor(address _tokenAddress) {
        nftToken = ERC721(_tokenAddress);
    }

    function createCollection(
        string memory name,
        string memory logoIPFS,
        string memory bannerIPFS,
        string memory description,
        string memory category
    ) public {
        collections[collectionCount] = Collection(
            collectionCount, // Assign the collection ID
            name,
            logoIPFS,
            bannerIPFS,
            description,
            category,
            msg.sender,
            false // Set isHidden to false by default

        );

        emit CollectionCreated(collectionCount, msg.sender, name);

        collectionCount++;
        totalCollections++; // Increment totalCollections here
    }

    function toggleCollectionHiddenStatus(uint256 collectionId) public {
    require(collections[collectionId].owner == msg.sender, "Only collection owner can toggle hidden status");
    collections[collectionId].isHidden = !collections[collectionId].isHidden;
}


    function getTokenPrice(address contractAddress, uint256 tokenId)
        public
        view
        returns (uint256 price)
    {
        Listing memory listing = listings[contractAddress][tokenId];
        require(listing.isActive, "Token not for sale");
        return listing.price;
    }

    function isTokenForSale(address contractAddress, uint256 tokenId)
        public
        view
        returns (bool)
    {
        Listing memory listing = listings[contractAddress][tokenId];
        return listing.isActive;
    }

    function getCollectionTokens(uint256 collectionId)
        public
        view
        returns (Token[] memory)
    {
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        Token[] memory tokens = collectionTokens[collectionId];

        return tokens;
    }

    function listCollectionForSale(uint256 collectionId, uint256 price)
        external
        onlyOwner
    {
        // Validate if the collection exists
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        Token[] memory tokens = collectionTokens[collectionId];

        for (uint256 i = 0; i < tokens.length; i++) {
            // Validate if the owner is calling
            require(
                ERC721(tokens[i].contractAddress).ownerOf(tokens[i].tokenId) ==
                    msg.sender,
                "Caller is not owner"
            );

            // Get the token listing
            Listing storage listing = listings[tokens[i].contractAddress][
                tokens[i].tokenId
            ];

            // Set the listing values
            listing.contractAddress = tokens[i].contractAddress;
            listing.tokenId = tokens[i].tokenId;
            listing.price = price;
            listing.seller = msg.sender;
            listing.isActive = true;

            // Add the token to the active listings
            activeListings.push(tokens[i]);

            emit TokenListed(tokens[i].tokenId, price, msg.sender);
        }
    }

    function addTokenToCollection(
        uint256 collectionId,
        address contractAddress,
        uint256 tokenId
    ) public onlyTokenOwner(contractAddress, tokenId) {
        // Check if the collection exists
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        // Check if the caller is the owner of the collection
        require(
            collections[collectionId].owner == msg.sender,
            "Only the collection owner can add tokens"
        );

        // Check if the token is already part of any collection
        require(
            !isTokenAddedToCollection[contractAddress][tokenId],
            "Token is already part of a collection"
        );

        // Add the token to the collection
        collectionTokens[collectionId].push(Token(contractAddress, tokenId));

        // Mark the token as added in the mapping
        isTokenAddedToCollection[contractAddress][tokenId] = true;
    }

    

    function getCollectionDetails(uint256 collectionId)
        public
        view
        returns (Collection memory, Token[] memory)
    {
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        Collection memory collection = collections[collectionId];
        Token[] memory tokens = collectionTokens[collectionId];

        return (collection, tokens);
    }

    function getCollectionOwner(uint256 collectionId)
        public
        view
        returns (address)
    {
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );
        return collections[collectionId].owner;
    }

    function getAllCollections(uint256 startIndex, uint256 pageSize)
        public
        view
        returns (Collection[] memory)
    {
        require(startIndex < collectionCount, "Start index out of range");

        uint256 actualPageSize = pageSize;

        // Check if the request is out of range
        if (startIndex + pageSize > collectionCount) {
            actualPageSize = collectionCount - startIndex;
        }

        Collection[] memory paginatedCollections = new Collection[](
            actualPageSize
        );

        for (uint256 i = 0; i < actualPageSize; i++) {
            paginatedCollections[i] = collections[startIndex + i];
        }

        return paginatedCollections;
    }

   
    function getCollectionCount() public view returns (uint256) {
        return collectionCount;
    }

    // This is the updated function, now it accepts separate arrays for tokenIds and contractAddresses.
    function BulkAddToCollection(
        uint256 collectionId,
        address[] memory contractAddresses,
        uint256[] memory tokenIds
    ) public {
        // Check if the collection exists
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        // Check if the caller is the owner of the collection
        require(
            collections[collectionId].owner == msg.sender,
            "Only the collection owner can add tokens"
        );

        // Check the limit of tokens that can be added
        require(
            tokenIds.length <= BATCH_PROCESS_LIMIT,
            "Exceeds batch process limit"
        );
        require(
            tokenIds.length == contractAddresses.length,
            "Mismatched input arrays"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Check if the caller is the owner of each token
            require(
                ERC721(contractAddresses[i]).ownerOf(tokenIds[i]) == msg.sender,
                "Only token owner can perform this action"
            );

            // Check if the token is already part of any collection
            require(
                !isTokenAddedToCollection[contractAddresses[i]][tokenIds[i]],
                "Token is already part of a collection"
            );

            // Add the tokens to the collection
            collectionTokens[collectionId].push(
                Token(contractAddresses[i], tokenIds[i])
            );

            // Mark the token as added in the mapping
            isTokenAddedToCollection[contractAddresses[i]][tokenIds[i]] = true;
        }
    }

    function getCollectionsByOwner(address owner)
        public
        view
        returns (Collection[] memory)
    {
        uint256 count = 0;

        // Count the number of collections owned by the given address
        for (uint256 i = 0; i < totalCollections; i++) {
            if (collections[i].owner == owner) {
                count++;
            }
        }

        // Create an array to store the collections
        Collection[] memory ownedCollections = new Collection[](count);
        uint256 index = 0;

        // Retrieve the collections owned by the given address
        for (uint256 i = 0; i < totalCollections; i++) {
            if (collections[i].owner == owner) {
                ownedCollections[index] = collections[i];
                index++;
            }
        }

        return ownedCollections;
    }

    // Fetch all tokens for sale
    function getAllTokensForSale()
        external
        view
        returns (TokenDetails[] memory)
    {
        uint256 length = activeListings.length;
        TokenDetails[] memory tokens = new TokenDetails[](length);

        for (uint256 i = 0; i < length; i++) {
            Token memory token = activeListings[i];
            Listing memory listing = listings[token.contractAddress][
                token.tokenId
            ];
            tokens[i] = TokenDetails(
                token.contractAddress,
                token.tokenId,
                listing.price,
                listing.seller
            );
        }

        return tokens;
    }

    // List a token for sale
    function listToken(
        address contractAddress,
        uint256 tokenId,
        uint256 price
    ) external payable onlyTokenOwner(contractAddress, tokenId) nonReentrant {
        require(msg.value >= listingFee, "Listing fee not provided");

        ERC721 tokenContract = ERC721(contractAddress);
        tokenContract.approve(address(this), tokenId);

        Listing storage listing = listings[contractAddress][tokenId];
        require(!listing.isActive, "Token is already listed for sale");

        listing.contractAddress = contractAddress;
        listing.tokenId = tokenId;
        listing.price = price;
        listing.seller = msg.sender;
        listing.isActive = true;

        Token memory token = Token(contractAddress, tokenId);
        activeListings.push(token);

        emit TokenListed(tokenId, price, msg.sender);
    }

    function buyToken(address contractAddress, uint256 tokenId)
        external
        payable
        nonReentrant
    {
        Listing storage listing = listings[contractAddress][tokenId];
        require(listing.isActive, "Token is not for sale");
        require(msg.value >= listing.price, "Insufficient funds to buy token");

        // Instantiate the ERC721 contract and IERC2981 interface
        ERC721 tokenContract = ERC721(listing.contractAddress);
        IERC2981 royaltyContract = IERC2981(listing.contractAddress);

        // Initialize royaltyRecipient and royaltyAmount
        address royaltyRecipient;
        uint256 royaltyAmount;

        // Try to call royaltyInfo function
        try royaltyContract.royaltyInfo(tokenId, listing.price) returns (
            address recipient,
            uint256 amount
        ) {
            royaltyRecipient = recipient;
            royaltyAmount = amount;
        } catch {
            royaltyRecipient = address(0);
            royaltyAmount = 0;
        }

        // Check if there's enough for the royalty
        require(
            listing.price >= royaltyAmount,
            "The price is less than the royalty."
        );

        // Mark the token as sold and store the sold price before making any transfers
        highestSoldPrice[contractAddress][tokenId] = listing.price;
        isTokenSold[contractAddress][tokenId] = true;

        // Transfer token ownership to the buyer
        tokenContract.safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        // Transfer funds to the seller minus the royalty
        uint256 sellerAmount = listing.price - royaltyAmount;
        payable(listing.seller).transfer(sellerAmount);

        // If royaltyRecipient is not the zero address, pay the royalty
        if (royaltyRecipient != address(0)) {
            payable(royaltyRecipient).transfer(royaltyAmount);
            emit TokenBought(tokenId, royaltyAmount, royaltyRecipient);
        }

        emit TokenSold(listing.tokenId, listing.seller, msg.sender);

        // Remove the listing
        delete listings[contractAddress][tokenId];

        // Update the activeListings array
        for (uint256 i = 0; i < activeListings.length; i++) {
            if (
                activeListings[i].contractAddress == contractAddress &&
                activeListings[i].tokenId == tokenId
            ) {
                if (i != activeListings.length - 1) {
                    activeListings[i] = activeListings[
                        activeListings.length - 1
                    ];
                }
                activeListings.pop();
                break;
            }
        }
    }

    function cancelListing(address contractAddress, uint256 tokenId)
        external
        onlyTokenOwner(contractAddress, tokenId)
        nonReentrant
    {
        require(
            listings[contractAddress][tokenId].isActive,
            "Token is not listed for sale"
        );

        delete listings[contractAddress][tokenId];

        // Update the activeListings array
        for (uint256 i = 0; i < activeListings.length; i++) {
            if (
                activeListings[i].contractAddress == contractAddress &&
                activeListings[i].tokenId == tokenId
            ) {
                if (i != activeListings.length - 1) {
                    activeListings[i] = activeListings[
                        activeListings.length - 1
                    ];
                }
                activeListings.pop();
                break;
            }
        }

        emit SaleCancelled(tokenId, msg.sender);
    }

    function setListingFee(uint256 _listingFee) external onlyOwner {
        listingFee = _listingFee;
    }

    //  BATCH FUNCTIONS

    // Batch listing function
    function listTokens(
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory prices
    ) external payable nonReentrant {
        require(
            contractAddresses.length == tokenIds.length &&
                tokenIds.length == prices.length &&
                prices.length > 0,
            "Mismatched input arrays"
        );
        require(
            msg.value >= listingFee * tokenIds.length,
            "Listing fee not provided"
        );

        uint256 tokensToProcess = contractAddresses.length;
        uint256 startIndex = 0;

        while (tokensToProcess > 0) {
            uint256 tokensInBatch = tokensToProcess > BATCH_PROCESS_LIMIT
                ? BATCH_PROCESS_LIMIT
                : tokensToProcess;
            address[] memory contractAddressesBatch = new address[](
                tokensInBatch
            );
            uint256[] memory tokenIdsBatch = new uint256[](tokensInBatch);
            uint256[] memory pricesBatch = new uint256[](tokensInBatch);

            for (uint256 i = 0; i < tokensInBatch; i++) {
                contractAddressesBatch[i] = contractAddresses[startIndex + i];
                tokenIdsBatch[i] = tokenIds[startIndex + i];
                pricesBatch[i] = prices[startIndex + i];
            }

            processListings(contractAddressesBatch, tokenIdsBatch, pricesBatch);

            startIndex += tokensInBatch;
            tokensToProcess -= tokensInBatch;
        }
    }

    function processListings(
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory prices
    ) internal {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            address contractAddress = contractAddresses[i];
            uint256 tokenId = tokenIds[i];
            uint256 price = prices[i];

            ERC721 tokenContract = ERC721(contractAddress);
            require(
                tokenContract.ownerOf(tokenId) == msg.sender,
                "Only token owner can perform this action"
            );

            tokenContract.approve(address(this), tokenId);

            listings[contractAddress][tokenId] = Listing(
                contractAddress,
                tokenId,
                price,
                msg.sender,
                true
            );

            // Add the token to the active listings
            activeListings.push(Token(contractAddress, tokenId));

            emit TokenListed(tokenId, price, msg.sender);
        }
    }


    // Batch canceling listings function
    function cancelListings(
        address[] memory contractAddresses,
        uint256[] memory tokenIds
    ) external nonReentrant {
        require(
            contractAddresses.length == tokenIds.length,
            "Mismatched input arrays"
        );

        for (uint256 i = 0; i < contractAddresses.length; i++) {
            address contractAddress = contractAddresses[i];
            uint256 tokenId = tokenIds[i];

            require(
                listings[contractAddress][tokenId].isActive,
                "Token is not listed for sale"
            );

            delete listings[contractAddress][tokenId];

            emit SaleCancelled(tokenId, msg.sender);
        }
    }

    function getHighestSalePrice(uint256 collectionId)
        public
        view
        returns (uint256)
    {
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        Token[] memory tokens = collectionTokens[collectionId];
        uint256 highestSalePrice = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory token = tokens[i];
            if (isTokenSold[token.contractAddress][token.tokenId]) {
                uint256 soldPrice = highestSoldPrice[token.contractAddress][
                    token.tokenId
                ];
                if (soldPrice > highestSalePrice) {
                    highestSalePrice = soldPrice;
                }
            }
        }

        return highestSalePrice;
    }

    function getFloorPrice(uint256 collectionId) public view returns (uint256) {
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        Token[] memory tokens = collectionTokens[collectionId];
        uint256 floorPrice = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Listing memory listing = listings[tokens[i].contractAddress][
                tokens[i].tokenId
            ];
            if (listing.isActive) {
                if (floorPrice == 0 || listing.price < floorPrice) {
                    floorPrice = listing.price;
                }
            }
        }

        return floorPrice;
    }

    function getMarketCap(uint256 collectionId) public view returns (uint256) {
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        Token[] memory tokens = collectionTokens[collectionId];
        uint256 marketCap = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Listing memory listing = listings[tokens[i].contractAddress][
                tokens[i].tokenId
            ];
            if (listing.isActive) {
                marketCap += listing.price;
            }
        }

        return marketCap;
    }

    function getItemsCount(uint256 collectionId) public view returns (uint256) {
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );
        return collectionTokens[collectionId].length;
    }

    function getOwnersCount(uint256 collectionId)
        public
        view
        returns (uint256)
    {
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        Token[] memory tokens = collectionTokens[collectionId];
        address[] memory ownerAddresses = new address[](tokens.length);
        uint256 ownersCount = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            Listing memory listing = listings[tokens[i].contractAddress][
                tokens[i].tokenId
            ];
            if (listing.isActive) {
                bool found = false;
                for (uint256 j = 0; j < ownersCount; j++) {
                    if (ownerAddresses[j] == listing.seller) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    ownerAddresses[ownersCount] = listing.seller;
                    ownersCount++;
                }
            }
        }

        return ownersCount;
    }

    function getTotalVolume(uint256 collectionId)
        public
        view
        returns (uint256)
    {
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        Token[] memory tokens = collectionTokens[collectionId];
        uint256 totalVolume = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (isTokenSold[tokens[i].contractAddress][tokens[i].tokenId]) {
                totalVolume += highestSoldPrice[tokens[i].contractAddress][
                    tokens[i].tokenId
                ];
            }
        }

        return totalVolume;
    }

    function deleteCollection(uint256 collectionId) external onlyOwner {
        require(
            collections[collectionId].owner != address(0),
            "Collection does not exist"
        );

        Token[] storage tokens = collectionTokens[collectionId];
        for (uint256 i = 0; i < tokens.length; i++) {
            address contractAddress = tokens[i].contractAddress;
            uint256 tokenId = tokens[i].tokenId;
            Listing storage listing = listings[contractAddress][tokenId];

            // Check if the token is listed and active
            if (listing.isActive) {
                // Return the listing price to the seller
                payable(listing.seller).transfer(listing.price);

                // Mark the listing as inactive and delete it
                listing.isActive = false;

                // Emit an event to signal that the listing has been deleted
                emit SaleCancelled(tokenId, listing.seller);
            }

            // Clear the token from the collection
            delete isTokenAddedToCollection[contractAddress][tokenId];
        }

        // Clear the collectionTokens array
        delete collectionTokens[collectionId];

        // Delete the collection
        delete collections[collectionId];
    }

    function deleteListing(address contractAddress, uint256 tokenId)
        external
        onlyOwner
    {
        Listing storage listing = listings[contractAddress][tokenId];
        require(listing.isActive, "Listing not found");

        // Return the listing price to the seller
        payable(listing.seller).transfer(listing.price);

        // Mark the listing as inactive and delete it
        listing.isActive = false;

        // Emit an event to signal that the listing has been deleted
        emit SaleCancelled(tokenId, listing.seller);
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");

        payable(owner()).transfer(balance);
    }

    // Function to withdraw any ERC721 tokens (NFTs) from contract
    function withdrawERC721(address _tokenContract, uint256 _tokenId)
        external
        onlyOwner
    {
        ERC721 tokenContract = ERC721(_tokenContract);
        tokenContract.safeTransferFrom(address(this), owner(), _tokenId);
    }

    // Function to withdraw any ERC20 tokens from contract
    function withdrawERC20(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), balance);
    }

   function getTop10HottestCollections() external view returns (Collection[] memory) {
    uint256 length = collectionCount; // Use the actual number of collections created

    // Sorting the collections in descending order of total volume using bubble sort
    Collection[] memory _collections = new Collection[](length);
    for (uint256 i = 0; i < length; i++) {
        _collections[i] = collections[i];
    }

    for (uint256 i = 0; i < length - 1; i++) {
        for (uint256 j = 0; j < length - i - 1; j++) {
            uint256 volume1 = getTotalVolume(_collections[j].collectionId);
            uint256 volume2 = getTotalVolume(_collections[j + 1].collectionId);
            if (volume1 < volume2) {
                Collection memory temp = _collections[j];
                _collections[j] = _collections[j + 1];
                _collections[j + 1] = temp;
            }
        }
    }

    // Selecting the top 10 collections
    uint256 count = length > 10 ? 10 : length;
    Collection[] memory top10Collections = new Collection[](count);
    for (uint256 i = 0; i < count; i++) {
        top10Collections[i] = _collections[i];
    }

    return top10Collections;
}





}
