// SPDX-License-Identifier: MIT pragma solidity ^0.8.20;

interface IERC20 { function transfer(address recipient, uint256 amount) external returns (bool); function balanceOf(address account) external view returns (uint256); function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); }

contract RewardPool { IERC20 public immutable absToken; address public immutable pancakeswapRouter; address public immutable icoContract; address public owner;

struct RewardInfo {
    uint256 eligibleBalance;
    uint256 lastClaim;
    uint256 baseAPY; // in basis points (800 = 8%)
    uint256 lastBuyTimestamp;
}

mapping(address => RewardInfo) public rewards;
mapping(address => bool) public excluded;

uint256 public constant DAY = 1 days;
uint256 public constant BASE_APY_DEX = 800; // 8.00%
uint256 public constant BASE_APY_ICO = 1200; // 12.00%
uint256 public constant MIN_APY = 1; // 0.001% as 1 bps

modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}

constructor(
    address _absToken,
    address _pancakeswapRouter,
    address _icoContract
) {
    absToken = IERC20(_absToken);
    pancakeswapRouter = _pancakeswapRouter;
    icoContract = _icoContract;
    owner = msg.sender;
}

function setExcluded(address user, bool status) external onlyOwner {
    excluded[user] = status;
}

function notifyBuy(address user, uint256 amount, bool fromICO) external {
    require(msg.sender == pancakeswapRouter || msg.sender == icoContract, "Unauthorized source");
    if (excluded[user]) return;

    RewardInfo storage info = rewards[user];

    if (fromICO) {
        // ICO buyer: 12% APY
        if (info.baseAPY == 0) {
            info.baseAPY = BASE_APY_ICO;
        }
    } else {
        // DEX buyer: override any existing APY to 8%
        info.baseAPY = BASE_APY_DEX;
    }

    info.eligibleBalance += amount;
    info.lastBuyTimestamp = block.timestamp;
}

function notifySellOrTransfer(address user) external onlyOwner {
    rewards[user].eligibleBalance = 0;
    rewards[user].baseAPY = 0;
}

function pendingReward(address user) public view returns (uint256) {
    RewardInfo memory info = rewards[user];
    if (info.eligibleBalance == 0) return 0;

    uint256 daysSinceLastClaim = (block.timestamp - info.lastClaim) / DAY;
    if (daysSinceLastClaim == 0) return 0;

    uint256 currentAPY = getDynamicAPY(user);
    uint256 rewardPerYear = (info.eligibleBalance * currentAPY) / 10000;
    uint256 reward = (rewardPerYear * daysSinceLastClaim) / 365;

    return reward;
}

function getDynamicAPY(address user) public view returns (uint256) {
    RewardInfo memory info = rewards[user];

    if (block.timestamp - info.lastBuyTimestamp <= 30 days) {
        return info.baseAPY;
    }

    uint256 daysInactive = (block.timestamp - info.lastBuyTimestamp - 30 days) / DAY;
    uint256 reduction = (info.baseAPY * 10 * daysInactive) / 100;

    if (reduction >= info.baseAPY - MIN_APY) {
        return MIN_APY;
    } else {
        return info.baseAPY - reduction;
    }
}

function claimReward() external {
    require(block.timestamp - rewards[msg.sender].lastClaim >= DAY, "Claim once per 24h");

    uint256 reward = pendingReward(msg.sender);
    require(reward > 0, "No reward available");

    rewards[msg.sender].lastClaim = block.timestamp;
    absToken.transfer(msg.sender, reward);
}

function recoverTokens(address to, uint256 amount) external onlyOwner {
    absToken.transfer(to, amount);
}

}

