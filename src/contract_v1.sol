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

    IERC20 public token;

    event FundsWithdrawn(uint256 platformShare, uint256 merchantShare);
    event PlatformFeeChanged(uint256 newPlatformFee);

    modifier onlyPlatform() {
        require(msg.sender == platform, "Only platform can call this function");
        _;
    }

    modifier onlyOwners() {
        require(msg.sender == merchant || msg.sender == platform, "Only merchant or platform can call this function");
        _;
    }

    constructor(address _merchant, address _platform, uint256 _platformFee, address _tokenAddress) {
        require(_platformFee <= 10000, "Platform fee cannot exceed 100%");
        merchant = _merchant;
        platform = _platform;
        platformFee = _platformFee;
        token = IERC20(_tokenAddress);
    }

    function withdrawFunds() external onlyOwners {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");

        uint256 platformShare = (balance * platformFee) / 10000;
        uint256 merchantShare = balance - platformShare;

        // Transfer the platform's share
        require(token.transfer(platform, platformShare), "Transfer to platform failed");

        // Transfer the merchant's share
        require(token.transfer(merchant, merchantShare), "Transfer to merchant failed");

        emit FundsWithdrawn(platformShare, merchantShare);
    }

    function setPlatformFee(uint256 _platformFee) external onlyPlatform {
        require(_platformFee <= 10000, "Platform fee cannot exceed 100%");
        platformFee = _platformFee;

        emit PlatformFeeChanged(_platformFee);
    }
}