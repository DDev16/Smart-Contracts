// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlockysAdventure is ERC20, Ownable {
    struct Player {
        address playerAddress;
        string name;
        uint256 tokens;
        uint256 blocksCollected;
        uint256 level;
        uint256 team;
        mapping(uint256 => bool) blockInventory;
        mapping(uint256 => uint256) itemInventory;
        mapping(uint256 => bool) badgeInventory;
    }
    
    struct Mission {
        string description;
        uint256 reward;
        bool completed;
    }
    
    struct Item {
        string name;
        uint256 cost;
    }
    
    struct Badge {
        string name;
        string achievement;
    }
    
    struct Team {
        string name;
        address leader;
        mapping(address => bool) members;
    }
    
    mapping(address => Player) public players;
    mapping(uint256 => Mission) public missions;
    mapping(uint256 => Item) public shopItems;
    mapping(uint256 => Badge) public badges;
    mapping(uint256 => Team) public teams;

    constructor() ERC20("BlockyToken", "BTK") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function registerPlayer(string memory _name) public {
        require(bytes(_name).length > 0, "Player name cannot be empty");
        require(players[msg.sender].playerAddress == address(0), "Player already registered");
        
        players[msg.sender] = Player(msg.sender, _name, 0, 0, 1, 0);
    }

    function rewardPlayer(address _playerAddress, uint256 _tokens) public onlyOwner {
        require(players[_playerAddress].playerAddress != address(0), "Player not registered");
        
        players[_playerAddress].tokens += _tokens;
        _mint(_playerAddress, _tokens);
    }

    function collectBlock(address _playerAddress, uint256 _blockId) public onlyOwner {
        require(players[_playerAddress].playerAddress != address(0), "Player not registered");
        
        players[_playerAddress].blocksCollected++;
        players[_playerAddress].blockInventory[_blockId] = true;
        
        // Level up the player every time they collect 10 blocks
        if (players[_playerAddress].blocksCollected % 10 == 0) {
            players[_playerAddress].level++;
        }
    }

    function tradeBlock(address _fromAddress, address _toAddress, uint256 _blockId) public {
        require(players[_fromAddress].playerAddress != address(0), "From player not registered");
        require(players[_toAddress].playerAddress != address(0), "To player not registered");
        require(players[_fromAddress].blockInventory[_blockId], "Block not found in inventory");

        players[_fromAddress].blocksCollected--;
        players[_fromAddress].blockInventory[_blockId] = false;
        
        players[_toAddress].blocksCollected++;
        players[_toAddress].blockInventory[_blockId] = true;
    }
    
    function createMission(uint256 _missionId, string memory _description, uint256 _reward) public onlyOwner {
        missions[_missionId] = Mission(_description, _reward, false);
    }
    
    function completeMission(uint256 _missionId, address _playerAddress) public onlyOwner {
        require(players[_playerAddress].playerAddress != address(0), "Player not registered");
        require(!missions[_missionId].completed, "Mission already completed");

        missions[_missionId].completed = true;
        players[_playerAddress].tokens += missions[_missionId].reward;
        _mint(_playerAddress, missions[_missionId].reward);
    }

    function createShopItem(uint256 _itemId, string memory _name, uint256 _cost) public onlyOwner {
        shopItems[_itemId] = Item(_name, _cost);
    }
    
    function buyItem(uint256 _itemId) public {
        require(players[msg.sender].playerAddress != address(0), "Player not registered");
        require(shopItems[_itemId].cost <= players[msg.sender].tokens, "Not enough tokens");
        
        players[msg.sender].tokens -= shopItems[_itemId].cost;
        players[msg.sender].itemInventory[_itemId]++;
        _burn(msg.sender, shopItems[_itemId].cost);
    }
    
    function createBadge(uint256 _badgeId, string memory _name, string memory _achievement) public onlyOwner {
        badges[_badgeId] = Badge(_name, _achievement);
    }
    
    function awardBadge(uint256 _badgeId, address _playerAddress) public onlyOwner {
        require(players[_playerAddress].playerAddress != address(0), "Player not registered");
        require(bytes(badges[_badgeId].name).length > 0, "Badge does not exist");
        
        players[_playerAddress].badgeInventory[_badgeId] = true;
    }

    function createTeam(uint256 _teamId, string memory _name, address _leader) public onlyOwner {
        require(players[_leader].playerAddress != address(0), "Player not registered");
        
        teams[_teamId] = Team(_name, _leader);
        teams[_teamId].members[_leader] = true;
        players[_leader].team = _teamId;
    }

    function joinTeam(uint256 _teamId, address _playerAddress) public {
        require(players[_playerAddress].playerAddress != address(0), "Player not registered");
        require(bytes(teams[_teamId].name).length > 0, "Team does not exist");
        
        teams[_teamId].members[_playerAddress] = true;
        players[_playerAddress].team = _teamId;
    }
}
