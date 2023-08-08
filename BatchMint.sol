// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNFTmint is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public mintingFee = 50 ether;
    uint256 public airdropFee = 0 ether;

    uint256 private freeMintsLimit = 2;
    mapping(address => uint256) private _freeMints;

    struct TokenInfo {
        string name;
        string description;
        string uri;
    }

    struct Collection {
        string name;
        uint256[] tokenIds;
    }

    mapping(uint256 => TokenInfo) private _tokenInfos;
    mapping(address => Collection[]) public userCollections;
    mapping(address => uint256[]) public collectionIDs;

    event Minted(uint256 tokenId, address owner);
    event Airdropped(uint256 tokenId, address recipient);
    event MintingFeeChanged(uint256 newMintingFee);
    event AirdropFeeChanged(uint256 newAirdropFee);

    constructor() ERC721("MyNFT", "MNFT") {}

    function _setTokenInfo(
        uint256 tokenId,
        string memory name,
        string memory description,
        string memory uri
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenInfos[tokenId] = TokenInfo(name, description, uri);
    }

    function createCollection(string memory name) public {
        Collection memory newCollection;
        newCollection.name = name;

        userCollections[msg.sender].push(newCollection);
        collectionIDs[msg.sender].push(userCollections[msg.sender].length - 1);
    }

    function addToCollection(uint256 collectionId, uint256 tokenId) public {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        require(
            ownerOf(tokenId) == msg.sender,
            "ERC721: approve caller is not owner nor approved for all"
        );

        require(
            collectionId < userCollections[msg.sender].length,
            "Collection does not exist"
        );

        userCollections[msg.sender][collectionId].tokenIds.push(tokenId);
    }

    function bulkAddToCollection(uint256 collectionId, uint256[] memory tokenIds) public {
    require(collectionId < userCollections[msg.sender].length, "Collection does not exist");

    for (uint256 i = 0; i < tokenIds.length; i++) {
        require(_isApprovedOrOwner(_msgSender(), tokenIds[i]), "ERC721: transfer caller is not owner nor approved");

        userCollections[msg.sender][collectionId].tokenIds.push(tokenIds[i]);
    }
}



    function getCollection(address user, uint256 collectionId) public view returns(string memory, uint256[] memory) {
        require(
            collectionId < userCollections[user].length,
            "Collection does not exist"
        );

        Collection memory collection = userCollections[user][collectionId];
        return (collection.name, collection.tokenIds);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        return _tokenInfos[tokenId].uri;
    }

    function getRemainingFreeMints(address walletAddress)
        public
        view
        returns (uint256)
    {
        return freeMintsLimit - _freeMints[walletAddress];
    }

    function mint(
        string memory name,
        string memory description,
        string memory metadataURI
    ) public payable returns (uint256) {
        if (_freeMints[msg.sender] < freeMintsLimit) {
            _freeMints[msg.sender]++;
        } else {
            require(
                msg.value >= mintingFee,
                "Not enough Ether provided."
            );
        }

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenInfo(newItemId, name, description, metadataURI);

        emit Minted(newItemId, msg.sender);

        return newItemId;
    }





    function batchMint(
        string[] memory names,
        string[] memory descriptions,
        string[] memory metadataURIs
    ) public payable returns (uint256[] memory) {
        require(
            names.length == descriptions.length &&
                names.length == metadataURIs.length,
            "Input arrays length mismatch"
        );
        require(
            msg.value >= mintingFee * names.length,
            "Not enough Ether provided for minting fees"
        );

        uint256[] memory newItemIds = new uint256[](names.length);

        for (uint256 i = 0; i < names.length; i++) {
            _tokenIds.increment();

            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            _setTokenInfo(newItemId, names[i], descriptions[i], metadataURIs[i]);

            emit Minted(newItemId, msg.sender);

            newItemIds[i] = newItemId;
        }

        return newItemIds;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = totalSupply();
            uint256 resultIndex = 0;

            for (uint256 tokenId = 1; tokenId <= totalTokens; tokenId++) {
                if (_exists(tokenId) && ownerOf(tokenId) == owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function batchTransfer(address recipient, uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(msg.sender, recipient, tokenIds[i]);
        }
    }

    function airdropNFTs(
        address[] memory recipients,
        uint256[] memory tokenIds
    ) public payable {
        require(
            msg.value >= airdropFee,
            "Not enough Ether provided for airdrop fee"
        );
        require(
            recipients.length == tokenIds.length,
            "recipients and tokenIds arrays must have the same length"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                ownerOf(tokenIds[i]) == msg.sender,
                "Caller must be the owner of the token"
            );
            safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);

            emit Airdropped(tokenIds[i], recipients[i]);
        }
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getTokenInfo(uint256 tokenId)
        public
        view
        returns (
            string memory name,
            string memory description,
            string memory uri
        )
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        TokenInfo memory info = _tokenInfos[tokenId];
        return (info.name, info.description, info.uri);
    }

    function setMintingFee(uint256 newMintingFee) public onlyOwner {
        mintingFee = newMintingFee;
        emit MintingFeeChanged(newMintingFee);
    }

    function getMintingFee() public view returns (uint256) {
        return mintingFee;
    }

    function setAirdropFee(uint256 newAirdropFee) public onlyOwner {
        airdropFee = newAirdropFee;
        emit AirdropFeeChanged(newAirdropFee);
    }

    function withdrawFees() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
