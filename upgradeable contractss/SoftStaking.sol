// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract StakingContract is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct Stake {
        address staker;
        address tokenContract;
        uint256 tokenId;
        uint256 stakedAt;
    }

    mapping(uint256 => Stake) public stakes;
    uint256 public stakeCounter;

    mapping(address => bool) public supportedERC721Contracts;

    event Staked(uint256 indexed stakeId, address indexed staker, address indexed tokenContract, uint256 tokenId);
    event Unstaked(uint256 indexed stakeId, address indexed staker, address indexed tokenContract, uint256 tokenId);

    function initialize() public initializer {
        __Ownable_init();
        
    }

    modifier onlySupportedContract(address tokenContract) {
        require(supportedERC721Contracts[tokenContract], "Unsupported ERC721 contract");
        _;
    }

    function addSupportedContract(address tokenContract) public onlyOwner {
        supportedERC721Contracts[tokenContract] = true;
    }

    function stake(address tokenContract, uint256 tokenId) public onlySupportedContract(tokenContract) {
        require(IERC721Upgradeable(tokenContract).ownerOf(tokenId) == msg.sender, "Not the token owner");

        uint256 stakeId = stakeCounter++;
        stakes[stakeId] = Stake({
            staker: msg.sender,
            tokenContract: tokenContract,
            tokenId: tokenId,
            stakedAt: block.timestamp
        });

        emit Staked(stakeId, msg.sender, tokenContract, tokenId);
    }

    function unstake(uint256 stakeId) public {
        Stake memory unstakedStake = stakes[stakeId];
        require(unstakedStake.staker == msg.sender, "Not the staker");

        require(IERC721Upgradeable(unstakedStake.tokenContract).ownerOf(unstakedStake.tokenId) == msg.sender, "Not the token owner");

        delete stakes[stakeId];

        emit Unstaked(stakeId, msg.sender, unstakedStake.tokenContract, unstakedStake.tokenId);
    }

    // New function to stake all tokens in the provided array
    function stakeAll(address tokenContract, uint256[] memory tokenIds) public onlySupportedContract(tokenContract) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stake(tokenContract, tokenIds[i]);
        }
    }

    // UUPS upgrade function
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
