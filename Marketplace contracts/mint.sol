// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract MyNFTmint is ERC721, Ownable, ReentrancyGuard, IERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public mintingFee = 50 ether;
    uint256 private freeMintsLimit = 2;
    mapping(address => uint256) private _freeMints;

    struct TokenInfo {
        string name;
        string description;
        string uri;
    }

    mapping(uint256 => TokenInfo) private _tokenInfos;

    mapping(uint256 => address payable) private _royaltyRecipients;
    mapping(uint256 => uint256) private _royalties;

    event Minted(uint256 tokenId, address owner);

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

    function approveTransfer(address nftContract, address to, uint256 tokenId) external {
    require(msg.sender == owner(), "Only contract owner can approve transfers");
    
    // Approve the transfer of the token to the specified address
    ERC721(nftContract).approve(to, tokenId);
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
        string memory metadataURI,
        address payable royaltyRecipient,
        uint256 royaltyBasisPoints
    ) public payable returns (uint256) {
        require(royaltyBasisPoints <= 10000, "Royalty can't be more than 100%.");

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
        _royaltyRecipients[newItemId] = royaltyRecipient;
        _royalties[newItemId] = royaltyBasisPoints;
        emit Minted(newItemId, msg.sender);

        return newItemId;
    }

    function batchMint(
        string[] memory names,
        string[] memory descriptions,
        string[] memory metadataURIs,
        address payable[] memory royaltyRecipients,
        uint256[] memory royaltyBasisPoints
    ) public payable returns (uint256[] memory) {
        require(
            names.length == descriptions.length &&
            names.length == metadataURIs.length &&
            names.length == royaltyRecipients.length &&
            names.length == royaltyBasisPoints.length,
            "Input arrays length mismatch"
        );
        require(
            msg.value >= mintingFee * names.length,
            "Not enough Ether provided for minting fees"
        );

        uint256[] memory newItemIds = new uint256[](names.length);

        for (uint256 i = 0; i < names.length; i++) {
            require(royaltyBasisPoints[i] <= 10000, "Royalty can't be more than 100%.");
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            _setTokenInfo(newItemId, names[i], descriptions[i], metadataURIs[i]);
            _royaltyRecipients[newItemId] = royaltyRecipients[i];
            _royalties[newItemId] = royaltyBasisPoints[i];
            emit Minted(newItemId, msg.sender);
            newItemIds[i] = newItemId;
        }

        return newItemIds;
    }

    function getRoyaltyBasisPoints(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721: Query for nonexistent token");
        return _royalties[tokenId];
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
    }

    function setFreeMintsLimit(uint256 newFreeMintsLimit) public onlyOwner {
        freeMintsLimit = newFreeMintsLimit;
    }

    function getMintingFee() public view returns (uint256) {
        return mintingFee;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        external 
        view 
        override 
        returns (address receiver, uint256 royaltyAmount) 
    {
        require(_exists(tokenId), "ERC721: Query for nonexistent token");
        uint256 royaltyBasisPoints = _royalties[tokenId];
        uint256 royalty = (salePrice * royaltyBasisPoints) / 10000;
        return (_royaltyRecipients[tokenId], royalty);
    }

    function withdrawFees() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getTokenDetails(uint256 tokenId)
        public
        view
        returns (
            string memory name,
            string memory description,
            string memory uri,
            address royaltyRecipient,
            uint256 royaltyBasisPoints
        )
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        TokenInfo memory info = _tokenInfos[tokenId];
        return (
            info.name,
            info.description,
            info.uri,
            _royaltyRecipients[tokenId],
            _royalties[tokenId]
        );
    }
}
