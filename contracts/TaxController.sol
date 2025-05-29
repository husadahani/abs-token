// SPDX-License-Identifier: MIT pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TaxController { IERC20 public absToken; address public owner; address public burnAddress = 0x000000000000000000000000000000000000dEaD; address public marketingWallet = 0x63821855deF5448f90cBDe2409F6bC32250D6508;

uint256 public baseTaxRate = 100; // 1% = 100 basis points
uint256 public maxTaxRate = 2000; // 20%
uint256 public dailyIncrease = 100; // 1% per day
uint256 public resetThreshold = 5 * 10**18; // $5 in USDT equivalent

mapping(address => uint256) public lastPurchase;
mapping(address => uint256) public currentTaxRate;

event TaxApplied(address indexed user, uint256 taxAmountBurn, uint256 taxAmountMarketing);
event TaxReset(address indexed user);

constructor(address _absToken) {
    absToken = IERC20(_absToken);
    owner = msg.sender;
}

modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}

function updateLastPurchase(address user) external onlyOwner {
    lastPurchase[user] = block.timestamp;
    currentTaxRate[user] = baseTaxRate;
    emit TaxReset(user);
}

function calculateTaxRate(address user) public view returns (uint256) {
    uint256 timeSince = block.timestamp - lastPurchase[user];
    if (timeSince > 30 days) timeSince = 30 days;

    uint256 increase = (timeSince / 1 days) * dailyIncrease;
    uint256 rate = baseTaxRate + increase;
    if (rate > maxTaxRate) {
        return maxTaxRate;
    }
    return rate;
}

function applyTax(address user, uint256 rewardAmount) external onlyOwner returns (uint256) {
    uint256 rate = calculateTaxRate(user);
    uint256 taxAmount = (rewardAmount * rate) / 10000;
    uint256 burnPart = taxAmount / 2;
    uint256 marketingPart = taxAmount - burnPart;

    require(absToken.transferFrom(user, burnAddress, burnPart), "Burn transfer failed");
    require(absToken.transferFrom(user, marketingWallet, marketingPart), "Marketing transfer failed");

    emit TaxApplied(user, burnPart, marketingPart);
    return rewardAmount - taxAmount;
}

function setMarketingWallet(address newWallet) external onlyOwner {
    marketingWallet = newWallet;
}

function setBurnAddress(address newBurnAddress) external onlyOwner {
    burnAddress = newBurnAddress;
}

}

