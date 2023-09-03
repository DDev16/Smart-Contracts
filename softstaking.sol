// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SoftStaking is Ownable {
    using SafeMath for uint256;

    IERC20 public rewardToken; // The token used for rewards
    uint256 public rewardPerNFT; // Reward amount per NFT per day
    uint256 public stakingStartTime; // UNIX timestamp when staking starts

    mapping(address => mapping(address => mapping(uint256 => uint256))) public stakedNFTs;

    constructor(
        address _rewardToken,
        uint256 _rewardPerNFT,
        uint256 _stakingStartTime
    ) {
        rewardToken = IERC20(_rewardToken);
        rewardPerNFT = _rewardPerNFT;
        stakingStartTime = _stakingStartTime;
    }

    // Stake an NFT
    function stakeNFT(address nftContract, uint256 tokenId) external {
        require(block.timestamp >= stakingStartTime, "Staking has not started yet");
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );

        stakedNFTs[msg.sender][nftContract][tokenId] = block.timestamp;
    }

    // Claim rewards
    function claimRewards(address nftContract, uint256 tokenId) external {
        uint256 stakingTimestamp = stakedNFTs[msg.sender][nftContract][tokenId];
        require(stakingTimestamp > 0, "You have not staked this NFT");

        uint256 elapsedTime = block.timestamp.sub(stakingTimestamp);
        uint256 rewards = rewardPerNFT.mul(elapsedTime).div(1 days);

        require(rewards > 0, "No rewards to claim");

        stakedNFTs[msg.sender][nftContract][tokenId] = block.timestamp;
        rewardToken.transfer(msg.sender, rewards);
    }

    // Update reward amount
    function updateRewardPerNFT(uint256 _newRewardPerNFT) external onlyOwner {
        rewardPerNFT = _newRewardPerNFT;
    }
}
