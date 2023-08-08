// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ColorMatchingGame {
    address public owner;
    mapping(address => uint256) public playerScores;
    mapping(address => uint256) public playerStars;
    uint256 public totalPlayers;

    constructor() {
        owner = msg.sender;
        totalPlayers = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the game owner can call this function.");
        _;
    }

    modifier validColor(uint8 color) {
        require(color >= 0 && color <= 4, "Invalid color choice. Choose a color between 0 and 4.");
        _;
    }

    event ScoreUpdated(address player, uint256 newScore);
    event StarsEarned(address player, uint256 earnedStars);
    event ToyPurchased(address player, string toyName);

    function matchColor(uint8 selectedColor) external validColor(selectedColor) {
        require(playerScores[msg.sender] < 100, "You have reached the maximum score.");

        // Simulate color matching logic (e.g., randomly generated target color)
        uint8 targetColor = uint8(blockhash(block.number - 1)[0]) % 5;
        if (selectedColor == targetColor) {
            playerScores[msg.sender]++;
            playerStars[msg.sender] += 5; // Earn 5 stars for every successful match
            emit StarsEarned(msg.sender, 5);
        }

        emit ScoreUpdated(msg.sender, playerScores[msg.sender]);
    }

    function getPlayerScore(address player) external view returns (uint256) {
        return playerScores[player];
    }

    function getPlayerStars(address player) external view returns (uint256) {
        return playerStars[player];
    }

    function getTotalPlayers() external view returns (uint256) {
        return totalPlayers;
    }

    function joinGame() external {
        require(playerScores[msg.sender] == 0, "You are already in the game.");
        totalPlayers++;
    }

    // Toy Shop: Exchange stars for virtual toys
    mapping(string => uint256) public toyPrices;
    mapping(address => mapping(string => bool)) public playerToys;

    function addToy(string memory toyName, uint256 price) external onlyOwner {
        toyPrices[toyName] = price;
    }

    function buyToy(string memory toyName) external {
        require(playerStars[msg.sender] >= toyPrices[toyName], "Not enough stars to buy this toy.");
        require(toyPrices[toyName] > 0, "This toy is not available.");

        playerStars[msg.sender] -= toyPrices[toyName];
        playerToys[msg.sender][toyName] = true;
        emit ToyPurchased(msg.sender, toyName);
    }

    function hasToy(address player, string memory toyName) external view returns (bool) {
        return playerToys[player][toyName];
    }
}
