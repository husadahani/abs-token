// Frontend interaction code
// app.js

const rewardPoolAddress = "0x98B7936935951B3Cd1cbE69F4344f22EF44cc013";
const rewardPoolAbi = [
  // Tambahkan ABI relevan untuk fungsi yang digunakan
  "function claimReward() external",
  "function getClaimableReward(address user) public view returns (uint256)",
  "function timeUntilNextClaim(address user) public view returns (uint256)",
  "event RewardClaimed(address indexed user, uint256 amount)"
];

let provider;
let signer;
let rewardPoolContract;

async function connectWallet() {
  if (window.ethereum) {
    provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    rewardPoolContract = new ethers.Contract(rewardPoolAddress, rewardPoolAbi, signer);

    const address = await signer.getAddress();
    document.getElementById("walletAddress").innerText = `Connected: ${address}`;
    updateRewardInfo();
  } else {
    alert("MetaMask not detected");
  }
}

async function updateRewardInfo() {
  try {
    const address = await signer.getAddress();
    const reward = await rewardPoolContract.getClaimableReward(address);
    const nextClaimTime = await rewardPoolContract.timeUntilNextClaim(address);

    document.getElementById("rewardAmount").innerText = `${ethers.utils.formatUnits(reward, 18)} ABS`;
    document.getElementById("nextClaim").innerText = `${(nextClaimTime / 3600).toFixed(2)} hours remaining`;

    document.getElementById("claimButton").disabled = reward.eq(0);
  } catch (err) {
    console.error(err);
    alert("Failed to load reward info.");
  }
}

async function claimReward() {
  try {
    const tx = await rewardPoolContract.claimReward();
    await tx.wait();
    alert("Reward claimed successfully!");
    updateRewardInfo();
  } catch (err) {
    console.error(err);
    alert("Claim failed.");
  }
}