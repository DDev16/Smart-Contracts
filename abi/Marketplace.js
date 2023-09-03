const Marketplace = {
	abi: [
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "_tokenAddress",
					"type": "address"
				}
			],
			"stateMutability": "nonpayable",
			"type": "constructor"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "owner",
					"type": "address"
				},
				{
					"indexed": false,
					"internalType": "string",
					"name": "name",
					"type": "string"
				}
			],
			"name": "CollectionCreated",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "address",
					"name": "previousOwner",
					"type": "address"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "newOwner",
					"type": "address"
				}
			],
			"name": "OwnershipTransferred",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "seller",
					"type": "address"
				}
			],
			"name": "SaleCancelled",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				},
				{
					"indexed": false,
					"internalType": "uint256",
					"name": "royalty",
					"type": "uint256"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "recipient",
					"type": "address"
				}
			],
			"name": "TokenBought",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				},
				{
					"indexed": false,
					"internalType": "uint256",
					"name": "price",
					"type": "uint256"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "seller",
					"type": "address"
				}
			],
			"name": "TokenListed",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "seller",
					"type": "address"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "buyer",
					"type": "address"
				}
			],
			"name": "TokenSold",
			"type": "event"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				},
				{
					"internalType": "address[]",
					"name": "contractAddresses",
					"type": "address[]"
				},
				{
					"internalType": "uint256[]",
					"name": "tokenIds",
					"type": "uint256[]"
				}
			],
			"name": "BulkAddToCollection",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"name": "activeListings",
			"outputs": [
				{
					"internalType": "address",
					"name": "contractAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "contractAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "addTokenToCollection",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "contractAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "buyToken",
			"outputs": [],
			"stateMutability": "payable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "contractAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "cancelListing",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address[]",
					"name": "contractAddresses",
					"type": "address[]"
				},
				{
					"internalType": "uint256[]",
					"name": "tokenIds",
					"type": "uint256[]"
				}
			],
			"name": "cancelListings",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "collectionCount",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"name": "collectionTokens",
			"outputs": [
				{
					"internalType": "address",
					"name": "contractAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"name": "collections",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				},
				{
					"internalType": "string",
					"name": "name",
					"type": "string"
				},
				{
					"internalType": "string",
					"name": "logoIPFS",
					"type": "string"
				},
				{
					"internalType": "string",
					"name": "bannerIPFS",
					"type": "string"
				},
				{
					"internalType": "string",
					"name": "description",
					"type": "string"
				},
				{
					"internalType": "string",
					"name": "category",
					"type": "string"
				},
				{
					"internalType": "address",
					"name": "owner",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "string",
					"name": "name",
					"type": "string"
				},
				{
					"internalType": "string",
					"name": "logoIPFS",
					"type": "string"
				},
				{
					"internalType": "string",
					"name": "bannerIPFS",
					"type": "string"
				},
				{
					"internalType": "string",
					"name": "description",
					"type": "string"
				},
				{
					"internalType": "string",
					"name": "category",
					"type": "string"
				}
			],
			"name": "createCollection",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				}
			],
			"name": "deleteCollection",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "contractAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "deleteListing",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "startIndex",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "pageSize",
					"type": "uint256"
				}
			],
			"name": "getAllCollections",
			"outputs": [
				{
					"components": [
						{
							"internalType": "uint256",
							"name": "collectionId",
							"type": "uint256"
						},
						{
							"internalType": "string",
							"name": "name",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "logoIPFS",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "bannerIPFS",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "description",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "category",
							"type": "string"
						},
						{
							"internalType": "address",
							"name": "owner",
							"type": "address"
						}
					],
					"internalType": "struct NFTMarketplace.Collection[]",
					"name": "",
					"type": "tuple[]"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "getAllTokensForSale",
			"outputs": [
				{
					"components": [
						{
							"internalType": "address",
							"name": "contractAddress",
							"type": "address"
						},
						{
							"internalType": "uint256",
							"name": "tokenId",
							"type": "uint256"
						},
						{
							"internalType": "uint256",
							"name": "price",
							"type": "uint256"
						},
						{
							"internalType": "address",
							"name": "seller",
							"type": "address"
						}
					],
					"internalType": "struct NFTMarketplace.TokenDetails[]",
					"name": "",
					"type": "tuple[]"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "getCollectionCount",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				}
			],
			"name": "getCollectionDetails",
			"outputs": [
				{
					"components": [
						{
							"internalType": "uint256",
							"name": "collectionId",
							"type": "uint256"
						},
						{
							"internalType": "string",
							"name": "name",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "logoIPFS",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "bannerIPFS",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "description",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "category",
							"type": "string"
						},
						{
							"internalType": "address",
							"name": "owner",
							"type": "address"
						}
					],
					"internalType": "struct NFTMarketplace.Collection",
					"name": "",
					"type": "tuple"
				},
				{
					"components": [
						{
							"internalType": "address",
							"name": "contractAddress",
							"type": "address"
						},
						{
							"internalType": "uint256",
							"name": "tokenId",
							"type": "uint256"
						}
					],
					"internalType": "struct NFTMarketplace.Token[]",
					"name": "",
					"type": "tuple[]"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				}
			],
			"name": "getCollectionOwner",
			"outputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				}
			],
			"name": "getCollectionTokens",
			"outputs": [
				{
					"components": [
						{
							"internalType": "address",
							"name": "contractAddress",
							"type": "address"
						},
						{
							"internalType": "uint256",
							"name": "tokenId",
							"type": "uint256"
						}
					],
					"internalType": "struct NFTMarketplace.Token[]",
					"name": "",
					"type": "tuple[]"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "owner",
					"type": "address"
				}
			],
			"name": "getCollectionsByOwner",
			"outputs": [
				{
					"components": [
						{
							"internalType": "uint256",
							"name": "collectionId",
							"type": "uint256"
						},
						{
							"internalType": "string",
							"name": "name",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "logoIPFS",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "bannerIPFS",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "description",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "category",
							"type": "string"
						},
						{
							"internalType": "address",
							"name": "owner",
							"type": "address"
						}
					],
					"internalType": "struct NFTMarketplace.Collection[]",
					"name": "",
					"type": "tuple[]"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				}
			],
			"name": "getFloorPrice",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				}
			],
			"name": "getHighestSalePrice",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				}
			],
			"name": "getItemsCount",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				}
			],
			"name": "getMarketCap",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				}
			],
			"name": "getOwnersCount",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "contractAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "getTokenPrice",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "price",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "getTop10HottestCollections",
			"outputs": [
				{
					"components": [
						{
							"internalType": "uint256",
							"name": "collectionId",
							"type": "uint256"
						},
						{
							"internalType": "string",
							"name": "name",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "logoIPFS",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "bannerIPFS",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "description",
							"type": "string"
						},
						{
							"internalType": "string",
							"name": "category",
							"type": "string"
						},
						{
							"internalType": "address",
							"name": "owner",
							"type": "address"
						}
					],
					"internalType": "struct NFTMarketplace.Collection[]",
					"name": "",
					"type": "tuple[]"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				}
			],
			"name": "getTotalVolume",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "contractAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "isTokenForSale",
			"outputs": [
				{
					"internalType": "bool",
					"name": "",
					"type": "bool"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "collectionId",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "price",
					"type": "uint256"
				}
			],
			"name": "listCollectionForSale",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "contractAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "price",
					"type": "uint256"
				}
			],
			"name": "listToken",
			"outputs": [],
			"stateMutability": "payable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address[]",
					"name": "contractAddresses",
					"type": "address[]"
				},
				{
					"internalType": "uint256[]",
					"name": "tokenIds",
					"type": "uint256[]"
				},
				{
					"internalType": "uint256[]",
					"name": "prices",
					"type": "uint256[]"
				}
			],
			"name": "listTokens",
			"outputs": [],
			"stateMutability": "payable",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "listingFee",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"name": "listings",
			"outputs": [
				{
					"internalType": "address",
					"name": "contractAddress",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				},
				{
					"internalType": "uint256",
					"name": "price",
					"type": "uint256"
				},
				{
					"internalType": "address",
					"name": "seller",
					"type": "address"
				},
				{
					"internalType": "bool",
					"name": "isActive",
					"type": "bool"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "nftToken",
			"outputs": [
				{
					"internalType": "contract ERC721",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "owner",
			"outputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "renounceOwnership",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "_listingFee",
					"type": "uint256"
				}
			],
			"name": "setListingFee",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "totalCollections",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "newOwner",
					"type": "address"
				}
			],
			"name": "transferOwnership",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "_tokenContract",
					"type": "address"
				}
			],
			"name": "withdrawERC20",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "_tokenContract",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "_tokenId",
					"type": "uint256"
				}
			],
			"name": "withdrawERC721",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "withdrawFees",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		}
	]
};
  
export default Marketplace;