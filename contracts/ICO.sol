// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ABSICO {
    address public owner;
    IERC20 public absToken;
    IERC20 public usdtToken;

    uint256 public startTimestamp;
    uint256 public constant DURATION = 180 days;
    uint256 public constant MAX_PER_WALLET_USDT = 50 * 10**18;
    uint256 public constant BASE_PRICE = 1e18 / 5_000_000_000; // 1 USDT = 5B ABS

    uint256 public priceIncreasePerBuy = 2; // 2%
    uint256 public maxPriceIncrease = 20;   // max +20%
    uint256 public currentPrice = BASE_PRICE;
    uint256 public totalBuys;

    mapping(address => uint256) public usdtSpent;
    mapping(address => bool) public hasPurchased;

    event ABSBought(address indexed buyer, uint256 usdtSpent, uint256 absReceived, uint256 newPrice);

    constructor(
        address _absToken,
        address _usdtToken,
        address _owner
    ) {
        absToken = IERC20(_absToken);
        usdtToken = IERC20(_usdtToken);
        owner = _owner;
    }

    modifier onlyWhileOpen() {
        require(startTimestamp == 0 || block.timestamp <= startTimestamp + DURATION, "ICO has ended");
        _;
    }

    function buyABS(uint256 usdtAmount) external onlyWhileOpen {
        require(!hasPurchased[msg.sender], "Only one purchase allowed per wallet");
        require(usdtAmount > 0, "Invalid USDT amount");
        require(usdtAmount <= MAX_PER_WALLET_USDT, "Exceeds wallet cap");

        uint256 tokens = (usdtAmount * 1e18) / currentPrice;

        require(usdtToken.transferFrom(msg.sender, owner, usdtAmount), "USDT transfer failed");
        require(absToken.transfer(msg.sender, tokens), "ABS transfer failed");

        usdtSpent[msg.sender] = usdtAmount;
        hasPurchased[msg.sender] = true;
        totalBuys += 1;

        // Increment price by 2% up to 20%
        uint256 maxPrice = BASE_PRICE + (BASE_PRICE * maxPriceIncrease / 100);
        if (currentPrice < maxPrice) {
            uint256 increased = (currentPrice * priceIncreasePerBuy) / 100;
            currentPrice = currentPrice + increased > maxPrice ? maxPrice : currentPrice + increased;
        }

        if (startTimestamp == 0) {
            startTimestamp = block.timestamp;
        }

        emit ABSBought(msg.sender, usdtAmount, tokens, currentPrice);
    }

    function getCurrentPrice() public view returns (uint256) {
        return currentPrice;
    }

    function getRemainingTime() public view returns (uint256) {
        if (startTimestamp == 0) return DURATION;
        if (block.timestamp > startTimestamp + DURATION) return 0;
        return (startTimestamp + DURATION) - block.timestamp;
    }
}