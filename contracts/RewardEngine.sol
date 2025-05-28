// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ABSToken.sol";

contract RewardEngine is Ownable {
    ABSToken public token;

    struct HolderInfo {
        uint256 totalBought;
        uint256 totalTransferred;
        uint256 lastClaimed;
        uint256 totalClaimed;
    }

    mapping(address => HolderInfo) public holders;
    uint256 public claimCooldown = 1 days;

    event RewardClaimed(address indexed user, uint256 amount);
    event PurchaseRecorded(address indexed user, uint256 amount);
    event TransferReset(address indexed user);

    constructor(address tokenAddress) {
        token = ABSToken(tokenAddress);
    }

    modifier onlyToken() {
        require(msg.sender == address(token), "Only token contract");
        _;
    }

    function recordPurchase(address buyer, uint256 amount) external onlyOwner {
        holders[buyer].totalBought += amount;
        emit PurchaseRecorded(buyer, amount);
    }

    function resetRewardOnTransfer(address user) external onlyOwner {
        holders[user].totalTransferred = holders[user].totalBought;
        emit TransferReset(user);
    }

    function claimReward() external {
        HolderInfo storage info = holders[msg.sender];
        require(block.timestamp - info.lastClaimed >= claimCooldown, "Wait before next claim");

        uint256 eligibleAmount = info.totalBought > info.totalTransferred
            ? info.totalBought - info.totalTransferred
            : 0;

        require(eligibleAmount > 0, "No reward eligible");

        uint256 reward = eligibleAmount * 8 / 100; // 8% APY approximation

        require(token.balanceOf(address(this)) >= reward, "Insufficient reward pool");
        info.lastClaimed = block.timestamp;
        info.totalClaimed += reward;

        token.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function setCooldown(uint256 _seconds) external onlyOwner {
        claimCooldown = _seconds;
    }

    function withdrawTokens(address to, uint256 amount) external onlyOwner {
        token.transfer(to, amount);
    }
}