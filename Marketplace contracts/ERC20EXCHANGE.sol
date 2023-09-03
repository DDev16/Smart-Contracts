// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface NFTMarketplace {
    // Define the required functions and variables from the NFTMarketplace contract
    function isTokenForSale(address contractAddress, uint256 tokenId) external view returns (bool);
    function getTokenPrice(address contractAddress, uint256 tokenId) external view returns (uint256);
    function getTokenSeller(address contractAddress, uint256 tokenId) external view returns (address);
    function listingFee() external view returns (uint256);
    function buyToken(address contractAddress, uint256 tokenId) external;
    function listToken(address contractAddress, uint256 tokenId, uint256 price) external;
    function cancelListing(address contractAddress, uint256 tokenId) external;
    // Add other functions and events as needed
}

contract NFTMarketplaceExchange is Ownable {
    using Address for address;

    NFTMarketplace private marketplaceContract;
    mapping(address => bool) private supportedTokens;
    address[] private supportedTokenList;

    constructor(address _marketplaceAddress) {
        marketplaceContract = NFTMarketplace(_marketplaceAddress);
    }

    // Add a new supported ERC20 token
    function addSupportedToken(address _tokenAddress) external onlyOwner {
        supportedTokens[_tokenAddress] = true;
        supportedTokenList.push(_tokenAddress);
    }

    // Function to buy NFT using ERC20 tokens
    function buyNFTWithTokens(
        address _contractAddress,
        uint256 _tokenId,
        address _tokenAddress
    ) external {
        require(supportedTokens[_tokenAddress], "Unsupported token");
        require(
            marketplaceContract.isTokenForSale(_contractAddress, _tokenId),
            "Token is not for sale"
        );

        uint256 tokenPrice = marketplaceContract.getTokenPrice(
            _contractAddress,
            _tokenId
        );
        address seller = marketplaceContract.getTokenSeller(
            _contractAddress,
            _tokenId
        );

        IERC20 erc20Token = IERC20(_tokenAddress);
        require(
            erc20Token.transferFrom(msg.sender, seller, tokenPrice),
            "Token transfer failed"
        );
        marketplaceContract.buyToken(_contractAddress, _tokenId);
    }

    // Function to list an NFT for sale using ERC20 tokens
    function listNFTForSaleWithTokens(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _tokenPrice,
        address _tokenAddress
    ) external {
        require(supportedTokens[_tokenAddress], "Unsupported token");
        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                marketplaceContract.listingFee()
            ),
            "Token transfer for listing fee failed"
        );
        marketplaceContract.listToken(_contractAddress, _tokenId, _tokenPrice);
    }

    // Function to cancel an NFT listing
    function cancelNFTListing(address _contractAddress, uint256 _tokenId) external onlyOwner {
        marketplaceContract.cancelListing(_contractAddress, _tokenId);
    }

    // Function to withdraw excess ERC20 tokens from the contract
    function withdrawExcessTokens(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "Token transfer failed");
    }

    // Function to withdraw excess ETH from the contract
    function withdrawExcessETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // Function to get the list of supported ERC20 tokens
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokenList;
    }
}
