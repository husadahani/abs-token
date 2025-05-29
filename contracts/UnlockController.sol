// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IABS {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IRewardPool {
    function receiveUnlockedTokens(uint256 amount) external;
}

contract UnlockController {
    address public owner;
    address public absToken;
    address public rewardPool;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant MAX_SUPPLY = 420_000_000_000_000 * 1e18; // 420 Triliun
    uint256 public unlockedSupply;
    uint256 public totalDistributed; // Catat distribusi total ke reward pool

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    event TokensUnlocked(uint256 amount, uint256 timestamp);

    constructor(address _absToken, address _rewardPool) {
        owner = msg.sender;
        absToken = _absToken;
        rewardPool = _rewardPool;
    }

    function circulatingSupply() public view returns (uint256) {
        uint256 burned = IABS(absToken).balanceOf(burnAddress);
        return unlockedSupply - burned;
    }

    function getRewardPoolBalance() public view returns (uint256) {
        return IABS(absToken).balanceOf(rewardPool);
    }

    function unlockIfNeeded() external onlyOwner {
        uint256 supplyInCirculation = circulatingSupply();
        uint256 rewardBalance = getRewardPoolBalance();

        if (supplyInCirculation == 0) revert("No circulation yet");

        // Cek apakah reward pool kurang dari 3% dari sirkulasi
        uint256 threshold = (supplyInCirculation * 3) / 100;
        if (rewardBalance >= threshold) {
            revert("Reward pool sufficient");
        }

        // Hitung jumlah token yang akan dibuka: maksimal 8%
        uint256 unlockAmount = (supplyInCirculation * 8) / 100;

        // Pastikan tidak melebihi maksimal supply
        require(unlockedSupply + unlockAmount <= MAX_SUPPLY, "Exceeds max supply");

        // Transfer dari UnlockController ke RewardPool
        bool success = IABS(absToken).transfer(rewardPool, unlockAmount);
        require(success, "Token transfer failed");

        unlockedSupply += unlockAmount;
        totalDistributed += unlockAmount;

        // Panggil fungsi receive di RewardPool (jika ada)
        IRewardPool(rewardPool).receiveUnlockedTokens(unlockAmount);

        emit TokensUnlocked(unlockAmount, block.timestamp);
    }
}