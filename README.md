
# 🥓 ABS Token – American Breakfast Token

> **Proof of Transaction Tokenomics. Fair, Modular, and Rewarding.**

## 🔗 Smart Contract
- **Network:** BNB Chain (BEP20)
- **Token Name:** American Breakfast
- **Token Symbol:** ABS
- **Max Supply:** 420,000,000,000,000 ABS
- **Contract Address:** *(to be updated after deployment)*

## 💡 Key Features

### ✅ Proof of Transaction (PoT)
- Rewards only for tokens that were purchased and never sold/transferred.
- Rewards are **reset** if user sells any of their tokens.

### 💰 Dynamic APY Rewards
- Initial APY: **8%**, claimable daily.
- If no token purchase occurs within **30 days**, APY decreases **10% per day** down to a minimum of **0.01%**.
- A purchase of at least **$5 USDT** resets APY back to 8%.

### 🔄 Reward Pool & Token Unlock
- Reward pool maintains **10% of circulating supply (excluding burned tokens)**.
- If reward pool drops to ≤ 3% of circulating supply, new tokens are **unlocked** from reserves.
- Triggered weekly.

### 🔥 Dynamic Tax
- Default: **1%** (50% burned, 50% to marketing wallet).
- If no purchase in 30 days, **tax increases 1% per day** up to a maximum of **20%**.
- A minimum purchase of $5 USDT resets tax to default 1%.

### 📦 Modular Architecture
Smart contract system is modular:
- `ABSToken.sol` – main token (no fee)
- `RewardEngine.sol` – calculate and distribute rewards
- `UnlockController.sol` – release tokens based on reward pool level
- `Airdrop.sol` – self-claim airdrop, once per wallet
- `ICO.sol` – crowdfunding token sale (optional)

## 📁 Project Structure

```bash
abs-token/
│
├── contracts/
│   ├── ABSToken.sol
│   ├── RewardEngine.sol
│   ├── UnlockController.sol
│   ├── Airdrop.sol
│   └── ICO.sol
│
├── scripts/
│   ├── deploy.js
│   └── config.json
│
├── frontend/ (optional)
│   └── index.html
│
├── wallet.json
├── LICENSE
├── .gitignore
└── README.md
```

## 🚀 Usage

- **Claim reward:** Once every 24 hours.
- **Rewards apply only to purchased tokens.** Transfers invalidate reward eligibility.
- **Burn address:** `0x000000000000000000000000000000000000dEaD`
- **DEX Router (PancakeSwap):** `0x10ED43C718714eb63d5aA57B78B54704E256024E`

## ⚖️ License

MIT License – open for community use and contribution.
