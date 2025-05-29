// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardPool is Ownable {
    IERC20 public absToken;
    address public pancakeswapRouter;
    address public icoContract;

    // Reward configuration
    uint256 public defaultAPY_Dex = 800;   // 8% APY (basis point = 10000)
    uint256 public icoAPY = 1200;          // 12% APY
    uint256 public minAPY = 1;             // 0.001% minimum

    // Addresses excluded from reward
    mapping(address => bool) public excluded;

    // Reward tracking
    struct RewardData {
        uint256 eligibleBalance;
        uint256 rewardRate;
        uint256 lastClaimTime;
        uint256 lastPurchaseTime;
    }

    mapping(address => RewardData) public rewards;

    // Event Logging
    event PurchaseRecorded(address indexed user, uint256 amount, uint256 rate);
    event RewardClaimed(address indexed user, uint256 rewardAmount);
    event RewardDisabled(address indexed user);
    event RouterSet(address indexed router);
    event IcoContractSet(address indexed icoContract);
    event Excluded(address indexed wallet, bool status);

    constructor(address _absToken) {
        absToken = IERC20(_absToken);
    }

    // Set router for DEX (PancakeSwap)
    function setPancakeRouter(address _router) external onlyOwner {
        pancakeswapRouter = _router;
        emit RouterSet(_router);
    }

    // Set ICO contract address
    function setICOContract(address _ico) external onlyOwner {
        icoContract = _ico;
        emit IcoContractSet(_ico);
    }

    // Exclude wallet from eligibility
    function setExcluded(address wallet, bool value) external onlyOwner {
        excluded[wallet] = value;
        emit Excluded(wallet, value);
    }

    // Called after user buys from DEX or ICO
    function recordPurchase(address buyer, uint256 amount) external {
        require(msg.sender == pancakeswapRouter || msg.sender == icoContract, "Not authorized");
        require(!excluded[buyer], "Excluded");

        RewardData storage data = rewards[buyer];

        if (data.eligibleBalance == 0) {
            data.lastClaimTime = block.timestamp;
        }

        // Override if ICO or downgrade if buyer ever uses DEX again
        if (msg.sender == icoContract) {
            if (data.rewardRate == 0) {
                data.rewardRate = icoAPY;
            }
        } else {
            data.rewardRate = defaultAPY_Dex;
        }

        data.eligibleBalance += amount;
        data.lastPurchaseTime = block.timestamp;

        emit PurchaseRecorded(buyer, amount, data.rewardRate);
    }

    // Called manually by user every 24h
    function claimReward() external {
        RewardData storage data = rewards[msg.sender];
        require(data.eligibleBalance > 0, "No eligible balance");
        require(block.timestamp >= data.lastClaimTime + 1 days, "Claim cooldown");

        uint256 apy = adjustedAPY(msg.sender);
        uint256 elapsed = block.timestamp - data.lastClaimTime;
        uint256 reward = (data.eligibleBalance * apy * elapsed) / (365 days * 10000);

        require(reward > 0, "No reward yet");
        require(absToken.balanceOf(address(this)) >= reward, "Insufficient pool balance");

        data.lastClaimTime = block.timestamp;
        absToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // Penonaktifan reward jika user transfer/sell
    function disableReward(address user) external onlyOwner {
        rewards[user].eligibleBalance = 0;
        rewards[user].rewardRate = 0;
        emit RewardDisabled(user);
    }

    // Penyesuaian APY jika user tidak beli token lagi
    function adjustedAPY(address user) public view returns (uint256) {
        RewardData storage data = rewards[user];
        if (block.timestamp <= data.lastPurchaseTime + 30 days) {
            return data.rewardRate;
        }

        // hitung hari pasif
        uint256 daysInactive = (block.timestamp - (data.lastPurchaseTime + 30 days)) / 1 days;
        uint256 reduction = (defaultAPY_Dex * daysInactive * 10) / 100; // 10% per hari dari defaultAPY

        if (reduction >= data.rewardRate) {
            return minAPY;
        }

        return data.rewardRate - reduction;
    }

    // Emergency Withdraw by owner
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        absToken.transfer(msg.sender, amount);
    }
}