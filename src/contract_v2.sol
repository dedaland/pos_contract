// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MerchantFundSplitter {
    address public merchant;
    address public platform;
    uint256 public platformFee; // Fee in basis points (e.g., 250 = 2.5%)

    mapping(address => bool) public supportedTokens;

    event FundsWithdrawn(address token, uint256 platformShare, uint256 merchantShare);
    event PlatformFeeChanged(uint256 newPlatformFee);
    event TokenAdded(address token);
    event TokenRemoved(address token);

    modifier onlyPlatform() {
        require(msg.sender == platform, "Only platform can call this function");
        _;
    }

    modifier onlyOwners() {
        require(msg.sender == merchant || msg.sender == platform, "Only merchant or platform can call this function");
        _;
    }

    constructor(address _merchant, address _platform, uint256 _platformFee) {
        require(_platformFee <= 10000, "Platform fee cannot exceed 100%");
        merchant = _merchant;
        platform = _platform;
        platformFee = _platformFee;
    }

    function addSupportedToken(address _tokenAddress) external onlyPlatform {
        require(_tokenAddress != address(0), "Invalid token address");
        supportedTokens[_tokenAddress] = true;

        emit TokenAdded(_tokenAddress);
    }

    function removeSupportedToken(address _tokenAddress) external onlyPlatform {
        require(supportedTokens[_tokenAddress], "Token is not supported");
        delete supportedTokens[_tokenAddress];

        emit TokenRemoved(_tokenAddress);
    }

    function withdrawFunds(address _tokenAddress) external onlyOwners {
        require(supportedTokens[_tokenAddress], "Token is not supported");
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");

        uint256 platformShare = (balance * platformFee) / 10000;
        uint256 merchantShare = balance - platformShare;

        // Transfer the platform's share
        require(token.transfer(platform, platformShare), "Transfer to platform failed");

        // Transfer the merchant's share
        require(token.transfer(merchant, merchantShare), "Transfer to merchant failed");

        emit FundsWithdrawn(_tokenAddress, platformShare, merchantShare);
    }

    function setPlatformFee(uint256 _platformFee) external onlyPlatform {
        require(_platformFee <= 10000, "Platform fee cannot exceed 100%");
        platformFee = _platformFee;

        emit PlatformFeeChanged(_platformFee);
    }
}