// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IABSToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract RewardPool {
    IABSToken public absToken;
    address public dexRouter;
    address public icoContract;

    uint256 public constant SECONDS_IN_YEAR = 365 * 24 * 60 * 60;
    uint256 public constant BASIS_POINTS = 10000; // 100.00%

    struct UserInfo {
        uint256 eligibleBalance;
        uint256 lastClaimTime;
        uint256 lastBuyTime;
        uint256 apy; // in basis points (e.g., 800 = 8%)
    }

    mapping(address => UserInfo) public users;

    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _absToken, address _dexRouter, address _icoContract) {
        absToken = IABSToken(_absToken);
        dexRouter = _dexRouter;
        icoContract = _icoContract;
    }

    modifier onlyEligibleClaimer() {
        require(block.timestamp >= users[msg.sender].lastClaimTime + 1 days, "Reward claim cooldown active");
        require(users[msg.sender].eligibleBalance > 0, "No eligible balance");
        _;
    }

    function claimReward() external onlyEligibleClaimer {
        UserInfo storage user = users[msg.sender];

        uint256 timeDiff = block.timestamp - user.lastClaimTime;
        uint256 adjustedAPY = getAdjustedAPY(msg.sender);
        uint256 reward = (user.eligibleBalance * adjustedAPY * timeDiff) / (SECONDS_IN_YEAR * BASIS_POINTS);

        require(reward > 0, "No reward available");

        user.lastClaimTime = block.timestamp;
        require(absToken.transfer(msg.sender, reward), "Transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }

    // Called after buy from PancakeSwap or ICO
    function recordPurchase(address buyer, uint256 amount, bool isICO) external {
        require(msg.sender == dexRouter || msg.sender == icoContract, "Unauthorized source");

        UserInfo storage user = users[buyer];

        // Reset if from PancakeSwap after ICO
        if (!isICO && user.apy == 1200) {
            user.apy = 800;
        } else if (isICO && user.apy == 0) {
            user.apy = 1200;
        } else if (user.apy == 0) {
            user.apy = 800;
        }

        user.eligibleBalance += amount;
        user.lastBuyTime = block.timestamp;
        if (user.lastClaimTime == 0) {
            user.lastClaimTime = block.timestamp;
        }
    }

    function disableReward(address userAddr) external {
        require(msg.sender == address(absToken), "Only ABS token can call");
        delete users[userAddr];
    }

    // --- View Functions For dApp ---

    function getClaimableReward(address userAddr) public view returns (uint256) {
        UserInfo memory user = users[userAddr];
        if (block.timestamp < user.lastClaimTime + 1 days) return 0;
        if (user.eligibleBalance == 0) return 0;

        uint256 timeDiff = block.timestamp - user.lastClaimTime;
        uint256 adjustedAPY = getAdjustedAPY(userAddr);

        return (user.eligibleBalance * adjustedAPY * timeDiff) / (SECONDS_IN_YEAR * BASIS_POINTS);
    }

    function timeUntilNextClaim(address userAddr) external view returns (uint256) {
        UserInfo memory user = users[userAddr];
        if (block.timestamp >= user.lastClaimTime + 1 days) return 0;
        return (user.lastClaimTime + 1 days) - block.timestamp;
    }

    function getEligibleBalance(address userAddr) external view returns (uint256) {
        return users[userAddr].eligibleBalance;
    }

    function getAdjustedAPY(address userAddr) public view returns (uint256) {
        UserInfo memory user = users[userAddr];
        if (user.lastBuyTime == 0) return 0;

        uint256 daysSinceBuy = (block.timestamp - user.lastBuyTime) / 1 days;

        if (user.apy == 800 && daysSinceBuy > 30) {
            uint256 reductions = daysSinceBuy - 30;
            uint256 decay = reductions * 800 / 10; // 10% decay per day
            if (decay >= 799) return 1; // minimum APY = 0.001%
            return 800 - decay;
        }

        return user.apy;
    }
}
