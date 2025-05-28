// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ABSToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 420_000_000_000_000 * 10**18; // 420 Triliun ABS
    bool public supplyLocked = false;
    address public rewardEngine;
    address public unlockController;
    address public airdrop;
    address public ico;

    constructor(
        address _rewardEngine,
        address _unlockController,
        address _airdrop,
        address _ico
    ) ERC20("American Breakfast Token", "ABS") {
        rewardEngine = _rewardEngine;
        unlockController = _unlockController;
        airdrop = _airdrop;
        ico = _ico;

        _transferOwnership(msg.sender);
    }

    modifier onlyControllers() {
        require(
            msg.sender == rewardEngine || 
            msg.sender == unlockController || 
            msg.sender == airdrop || 
            msg.sender == ico || 
            msg.sender == owner(),
            "Not authorized"
        );
        _;
    }

    function mint(address to, uint256 amount) external onlyControllers {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function setRewardEngine(address _engine) external onlyOwner {
        rewardEngine = _engine;
    }

    function setUnlockController(address _controller) external onlyOwner {
        unlockController = _controller;
    }

    function setAirdrop(address _airdrop) external onlyOwner {
        airdrop = _airdrop;
    }

    function setICO(address _ico) external onlyOwner {
        ico = _ico;
    }

    function circulatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(0x000000000000000000000000000000000000dEaD);
    }
}