// app.js

const web3 = new Web3(window.ethereum);

// Replace with deployed contract address and ABI const icoContractAddress = "0x2F234aB882B01c4e0B9A7978a74a41e249660CF9"; const icoAbi = [ { "inputs": [ { "internalType": "address", "name": "_absToken", "type": "address" }, { "internalType": "address", "name": "_usdtToken", "type": "address" }, { "internalType": "address", "name": "_owner", "type": "address" } ], "stateMutability": "nonpayable", "type": "constructor" }, { "anonymous": false, "inputs": [ { "indexed": true, "internalType": "address", "name": "buyer", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "usdtSpent", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "absReceived", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "newPrice", "type": "uint256" } ], "name": "ABSBought", "type": "event" }, { "inputs": [ { "internalType": "uint256", "name": "usdtAmount", "type": "uint256" } ], "name": "buyABS", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "getCurrentPrice", "outputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "", "type": "address" } ], "name": "hasPurchased", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "view", "type": "function" } ];

const icoContract = new web3.eth.Contract(icoAbi, icoContractAddress);

async function buyABS() { const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' }); const userAddress = accounts[0];

const usdtAmount = document.getElementById("usdtAmount").value;

const hasPurchased = await icoContract.methods.hasPurchased(userAddress).call(); if (hasPurchased) { alert("You have already purchased from the ICO."); return; }

try { await icoContract.methods.buyABS(web3.utils.toWei(usdtAmount, 'ether')).send({ from: userAddress }); alert("ABS token purchase successful."); } catch (error) { console.error("Transaction failed", error); alert("Transaction failed: " + error.message); } }

document.getElementById("buyButton").addEventListener("click", buyABS);

