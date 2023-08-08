// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract ERC721Interface {
    function safeTransferFrom (address _from , address _to, uint256 _tokenId) public virtual;
}

abstract contract ERC1155Interface {
    function safeTransferFrom (address _from , address _to, uint256 _tokenId, uint256 _amount, bytes memory data) public virtual;
}

contract NFTMultiSender {

    function erc721Airdrop(address _addressOfNFT, address[] memory _recipients, uint256[] memory _tokenIds) public {
        ERC721Interface erc721 = ERC721Interface(_addressOfNFT); 
        for(uint i = 0; i < _recipients.length; i++) {
            erc721.safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i]);
        }
    }

     function erc1155Airdrop(address _addressOfNFT, address[] memory _recipients, uint256[] memory _ids, uint256[] memory _amounts) public {
        ERC1155Interface erc1155 = ERC1155Interface(_addressOfNFT); 
        for(uint i = 0; i < _recipients.length; i++) {
            erc1155.safeTransferFrom(msg.sender, _recipients[i], _ids[i], _amounts[i], "");
        }
    }
}