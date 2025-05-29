// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AmericanBreakfast is ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 420_000_000_000_000 * 10**18;
    uint256 public constant INITIAL_SUPPLY = 980_000_000_000 * 10**18;

    address public immutable REWARD_POOL;
    address public immutable AIRDROP_DISTRIBUTOR;
    address public immutable ICO_WALLET;
    address public immutable MARKETING_WALLET;
    address public immutable LIQUIDITY_WALLET;

    event InitialDistribution(
        address indexed recipient,
        uint256 amount,
        string purpose
    );

    constructor(
        address _rewardPool,
        address _airdropDistributor,
        address _icoWallet,
        address _marketingWallet
    ) ERC20("American Breakfast", "ABS") {
        require(_rewardPool != address(0), "Invalid reward pool");
        require(_airdropDistributor != address(0), "Invalid airdrop");
        require(_icoWallet != address(0), "Invalid ICO wallet");
        require(_marketingWallet != address(0), "Invalid marketing wallet");

        REWARD_POOL = _rewardPool;
        AIRDROP_DISTRIBUTOR = _airdropDistributor;
        ICO_WALLET = _icoWallet;
        MARKETING_WALLET = _marketingWallet;
        LIQUIDITY_WALLET = msg.sender;

        uint256 toRewardPool = (INITIAL_SUPPLY * 35) / 100; // 35%
        uint256 toAirdrop = (INITIAL_SUPPLY * 10) / 100;     // 10%
        uint256 toICO = (INITIAL_SUPPLY * 25) / 100;         // 25%
        uint256 toMarketing = (INITIAL_SUPPLY * 10) / 100;   // 10%
        uint256 toOwner = INITIAL_SUPPLY - (toRewardPool + toAirdrop + toICO + toMarketing);

        _mint(REWARD_POOL, toRewardPool);
        emit InitialDistribution(REWARD_POOL, toRewardPool, "Reward Pool");

        _mint(AIRDROP_DISTRIBUTOR, toAirdrop);
        emit InitialDistribution(AIRDROP_DISTRIBUTOR, toAirdrop, "Airdrop Distributor");

        _mint(ICO_WALLET, toICO);
        emit InitialDistribution(ICO_WALLET, toICO, "ICO Wallet");

        _mint(MARKETING_WALLET, toMarketing);
        emit InitialDistribution(MARKETING_WALLET, toMarketing, "Marketing Wallet");

        _mint(LIQUIDITY_WALLET, toOwner);
        emit InitialDistribution(LIQUIDITY_WALLET, toOwner, "Liquidity / Owner");
    }
}