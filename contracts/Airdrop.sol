// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract AirdropDistributor {
    address public owner;
    address public absToken;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant MAX_CLAIM_WALLETS = 49000;
    uint256 public constant TOTAL_AIRDROP_TOKENS = 98_000_000_000 * 1e18; // 98 miliar ABS
    uint256 public constant AIRDROP_DURATION = 180 days;

    uint256 public claimedWallets;
    uint256 public claimStartTimestamp;
    bool public started;
    bool public finalized;

    mapping(address => bool) public hasClaimed;

    event AirdropClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event AirdropFinalized(uint256 burnedAmount, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier whenActive() {
        require(started, "Airdrop not started");
        require(block.timestamp <= claimStartTimestamp + AIRDROP_DURATION, "Airdrop expired");
        require(!finalized, "Airdrop finalized");
        _;
    }

    constructor(address _absToken) {
        owner = msg.sender;
        absToken = _absToken;
    }

    function startAirdrop() external onlyOwner {
        require(!started, "Already started");
        claimStartTimestamp = block.timestamp;
        started = true;
    }

    function claimAirdrop() external whenActive {
        require(!hasClaimed[msg.sender], "Already claimed");
        require(claimedWallets < MAX_CLAIM_WALLETS, "Max wallet reached");

        uint256 amountPerWallet = TOTAL_AIRDROP_TOKENS / MAX_CLAIM_WALLETS;

        bool success = IToken(absToken).transfer(msg.sender, amountPerWallet);
        require(success, "Transfer failed");

        hasClaimed[msg.sender] = true;
        claimedWallets += 1;

        emit AirdropClaimed(msg.sender, amountPerWallet, block.timestamp);
    }

    function finalizeAirdrop() external onlyOwner {
        require(started, "Not started");
        require(block.timestamp > claimStartTimestamp + AIRDROP_DURATION, "Not expired yet");
        require(!finalized, "Already finalized");

        uint256 remainingTokens = IToken(absToken).balanceOf(address(this));

        if (remainingTokens > 0) {
            IToken(absToken).transfer(burnAddress, remainingTokens);
        }

        finalized = true;
        emit AirdropFinalized(remainingTokens, block.timestamp);
    }

    function isAirdropActive() external view returns (bool) {
        return started && block.timestamp <= claimStartTimestamp + AIRDROP_DURATION && !finalized;
    }

    function timeLeft() external view returns (uint256) {
        if (!started || finalized) return 0;
        if (block.timestamp >= claimStartTimestamp + AIRDROP_DURATION) return 0;
        return (claimStartTimestamp + AIRDROP_DURATION) - block.timestamp;
    }
}