// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

// V2: removed harvest batch threshold
// V3: fixed exploits (and introduced bugs :D)
// V4: harvest batch totalized, minor changes
// V5: unstake loc changes
// V6: remove harvest on unstake
// V7: upgraded for the release

contract MonsterCoinStaking is
    Initializable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    ERC20BurnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
        _transferOwnership(address(0x84B33A53a6E59eC8EC1bEAAB24495F7555b781ab));
    }
   
   

    IERC721Enumerable public collection;
    ERC20BurnableUpgradeable public token;
    
    bool public paused;

    uint256 public tokensStaked;

    struct StakeInfo {
        uint256 tokenId;
        uint256 start;
        uint256 tier;
        bool status;
    }

    mapping(address => mapping(uint256 => StakeInfo)) public stakes;

    mapping(address => uint256) public tokensStakedByUser;

    mapping(address => uint256[]) private userStakedPortfolio;

    mapping(uint256 => uint256) public indexOfTokenIdInStakePortfolio;

    function initialize(address collectionAddr, address tokenAddr)
        public
        initializer
    {        
        __ERC20Burnable_init();
        __ERC721Holder_init();
        __Ownable_init();
        paused = false;
        _transferOwnership(address(0x84B33A53a6E59eC8EC1bEAAB24495F7555b781ab));
        collection = IERC721Enumerable(collectionAddr);
        token = ERC20BurnableUpgradeable(tokenAddr);
        
    }




  function reward(uint256 tokenId) public view returns (uint256) {
        require(!paused, "The contract is paused");
        StakeInfo storage info = stakes[msg.sender][tokenId];
        require(info.tier < 5, "Cannot upgrade anymore!");
        if (info.tier == 0) {
            return 100 ether;
        }
        if (info.tier == 1) {
            return 150 ether;
        }
        if (info.tier == 2) {
            return 200 ether;
        }
        if (info.tier == 3) {
            return 250 ether;
        }
        if (info.tier >= 4) {
            return 350 ether;
        }
    }



    function stakedNFTSByUser(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return userStakedPortfolio[owner];
    }

    function pendingRewards(uint256 tokenId) public view returns (uint256) {
        StakeInfo memory info = stakes[msg.sender][tokenId];
        uint256 timeStarted = info.start;
        uint256 timeNow = block.timestamp;
        uint256 timePassed = timeNow - timeStarted;
        return (timePassed * reward(tokenId)) / 86400;
    }

    function totalPendingRewards() public view returns (uint256) {
        uint256 total;
        uint256[] memory tokens = userStakedPortfolio[msg.sender];
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tempRewards = pendingRewards(tokens[i]);
            if (tokens[i] == 0) {
                continue;
            }
            total += tempRewards;
        }
        return total;
    }

    function harvest(uint256 tokenId) public {
        require(!paused, "The contract is paused");
        require(
            collection.ownerOf(tokenId) == address(this),
            "You need to stake the token first!"
        );
        StakeInfo storage info = stakes[msg.sender][tokenId];
        require(info.status, "This token is not staked by caller");
        uint256 rewardAmount = pendingRewards(tokenId);
        if (rewardAmount > 0) {
            info.start = block.timestamp;
            bool success = token.transfer(msg.sender, rewardAmount);
            require(success, "An error occurred during transfer");
        }
    }

    function harvestBatch(address user) external {
        require(!paused, "The contract is paused");
        require(user == msg.sender, "Caller is not the user");
        uint256[] memory tokenIds = userStakedPortfolio[user];
        uint256 total = 0;
        for (uint256 currentId = 0; currentId < tokenIds.length; currentId++) {
            if (tokenIds[currentId] == 0) {
                continue;
            }

            StakeInfo storage info = stakes[msg.sender][tokenIds[currentId]];
            uint256 rewardAmount = pendingRewards(tokenIds[currentId]);
            if (rewardAmount > 0) {
                info.start = block.timestamp;
                total += rewardAmount;
            }
        }

        if (total > 0) {
            bool success = token.transfer(msg.sender, total);
            require(success, "An error occurred during transfer");
        }
    }

    function currentTier(uint256 tokenId) public view returns (uint256) {
        StakeInfo storage info = stakes[msg.sender][tokenId];
        return info.tier;
    }

   function upgradeTokenRewardTier(uint256 tokenId) public {
        require(!paused, "The contract is paused");
        require(
            collection.ownerOf(tokenId) == address(this),
            "You need to stake the token first!"
        );
        StakeInfo storage info = stakes[msg.sender][tokenId];
        uint256 tier = currentTier(tokenId);
        require(
            token.allowance(msg.sender, address(this)) >=
                (tier * 5 + 900) * 10**18,
            "Not enough ERC20 allowance"
        );
        require(tier < 4, "Token already reached maximum tier");
        if (tier == 0) {
            info.tier = 1;
            bool success = token.transferFrom(msg.sender, owner(), 900 ether);
            require(success, "Problem during token transfers");
        }
        if (tier == 1) {
            info.tier = 2;
            bool success = token.transferFrom(msg.sender, owner(), 1350 ether);
            require(success, "Problem during token transfers");
        }
        if (tier == 2) {
            info.tier = 3;
            bool success = token.transferFrom(msg.sender, owner(), 1800 ether);
            require(success, "Problem during token transfers");
        }
        if (tier == 3) {
            info.tier = 4;
            bool success = token.transferFrom(msg.sender, owner(), 2250 ether);
            require(success, "Problem during token transfers");
        }
    }

    // ! need erc721 approval beforehand
    function stake(uint256 tokenId) public {
        require(!paused, "The contract is paused");
        collection.safeTransferFrom(msg.sender, address(this), tokenId);
        require(
            collection.ownerOf(tokenId) == address(this),
            "Error while transferring!"
        );
        StakeInfo storage info = stakes[msg.sender][tokenId];
        info.tokenId = tokenId;
        info.start = block.timestamp;
        info.tier = 0;
        info.status = true;
        tokensStakedByUser[msg.sender] += 1;
        tokensStaked += 1;
        userStakedPortfolio[msg.sender].push(tokenId);
        uint256 indexOfNewElement = userStakedPortfolio[msg.sender].length - 1;
        indexOfTokenIdInStakePortfolio[tokenId] = indexOfNewElement;
    }

    // ! need erc721 approval beforehand
    function stakeBatch() external {
        require(!paused, "The contract is paused");
        uint256[] memory tokenIds = walletOfOwner(msg.sender);
        // ! changed
        uint256 threshold = tokenIds.length >= 50 ? 50 : tokenIds.length;
        for (uint256 currentId = 0; currentId < threshold; currentId++) {
            if (tokenIds[currentId] == 0) {
                continue;
            }
            stake(tokenIds[currentId]);
        }
    }

    function unstake(uint256 tokenId) public {
        require(!paused, "The contract is paused");
        StakeInfo storage info = stakes[msg.sender][tokenId];
        require(info.status, "This token is not staked by caller");
        /*if (pendingRewards(tokenId) > 0) {
            harvest(tokenId);
        }*/
        info.start = 0;
        info.tier = 0;
        info.status = false;
        collection.safeTransferFrom(address(this), msg.sender, tokenId);
        require(
            collection.ownerOf(tokenId) == msg.sender,
            "Error while transferring!"
        );
        tokensStakedByUser[msg.sender] -= 1;
        tokensStaked -= 1;
        userStakedPortfolio[msg.sender][
            indexOfTokenIdInStakePortfolio[tokenId]
        ] = 0;
    }

    function unstakeBatch() external {
        require(!paused, "The contract is paused");
        uint256[] memory tokenIds = userStakedPortfolio[msg.sender];
        uint256 threshold = tokenIds.length >= 50 ? 50 : tokenIds.length;
        for (uint256 currentId = 0; currentId < threshold; currentId++) {
            if (tokenIds[currentId] == 0) {
                threshold += 1;
                continue;
            }
            unstake(tokenIds[currentId]);
        }
    }

    /** INTERNAL FUNCTIONS */
    function walletOfOwner(address account)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 erc721Balance = collection.balanceOf(account);
        uint256[] memory tokenIdsOwned = new uint256[](erc721Balance);
        for (uint256 i = 0; i < erc721Balance; i++) {
            tokenIdsOwned[i] = collection.tokenOfOwnerByIndex(account, i);
        }
        return tokenIdsOwned;
    }

    /** ONLY OWNER FUNCTIONS */
    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function emergencyWithdraw(uint256 amount) external onlyOwner {
        bool success = token.transfer(msg.sender, amount);
        require(success, "An error occurred during ERC20 transfer");
    }

    function release(address user) external onlyOwner {
        uint256[] memory tokenIds = userStakedPortfolio[user];
        for (uint256 currentId = 0; currentId < tokenIds.length; currentId++) {
            if (tokenIds[currentId] == 0) {
                continue;
            }
            uint256 currentTokenId = tokenIds[currentId];
            StakeInfo storage info = stakes[user][currentTokenId];
            require(info.status, "This token is not staked by the given user");
            info.start = 0;
            info.tier = 0;
            info.status = false;
            collection.safeTransferFrom(address(this), user, currentTokenId);
            require(
                collection.ownerOf(currentTokenId) == user,
                "Error while transferring!"
            );
            tokensStakedByUser[user] -= 1;
            tokensStaked -= 1;
            userStakedPortfolio[user][
                indexOfTokenIdInStakePortfolio[currentTokenId]
            ] = 0;
        }
    }

    function setCollection(address addr) external onlyOwner {
        collection = IERC721Enumerable(addr);
    }

    function setToken(address addr) external onlyOwner {
        token = ERC20BurnableUpgradeable(addr);
    }
}
