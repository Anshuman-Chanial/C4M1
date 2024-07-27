// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault {
    IERC20 public immutable token;

    mapping(address => uint) public balanceOf;
    uint public totalSupply;

    struct Player {
        uint level;
        uint upgradeCost;
        uint lastRewardTime;
    }

    mapping(address => Player) private players;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event Upgrade(address indexed user, uint newLevel, uint newUpgradeCost);
    event RewardCollected(address indexed user, uint rewardAmount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(uint _amount) external {
        require(_amount > 0, "Deposit amount must be greater than zero");

        token.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint _amount) external {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        token.transfer(msg.sender, _amount);
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;

        emit Withdraw(msg.sender, _amount);
    }

    function upgradePlayer() external {
        Player storage player = players[msg.sender];
        require(player.level > 0, "Player not initialized");

        uint cost = player.upgradeCost;
        require(balanceOf[msg.sender] >= cost, "Insufficient deposited tokens");

        balanceOf[msg.sender] -= cost;
        totalSupply -= cost;

        player.level += 1;
        player.upgradeCost = cost * 2;

        emit Upgrade(msg.sender, player.level, player.upgradeCost);
    }

    function getPlayerInfo(address _player) external view returns (uint level, uint upgradeCost) {
        Player storage player = players[_player];
        return (player.level, player.upgradeCost);
    }

    function dailyRewards() external {
        Player storage player = players[msg.sender];
        require(player.level > 0, "Player not initialized");

        uint currentTime = block.timestamp;
        require(currentTime >= player.lastRewardTime + 1 days, "Rewards can only be collected once a day");

        uint rewardAmount = player.level * 2;

        balanceOf[msg.sender] += rewardAmount;
        totalSupply += rewardAmount;
        player.lastRewardTime = currentTime;


        emit RewardCollected(msg.sender, rewardAmount);
    }


    function initializePlayer() external {
        Player storage player = players[msg.sender];
        require(player.level == 0, "Player already initialized");
        player.level = 1;
        player.upgradeCost = 100;
    }
}
