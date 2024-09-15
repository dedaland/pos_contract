// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title MerchantFundSplitter
/// @notice This contract splits funds between a merchant and a platform
contract MerchantFundSplitter is Ownable, ReentrancyGuard {
    address public immutable merchant;
    address public platform;
    uint256 public platformFee; // Fee in basis points (e.g., 250 = 2.5%)

    mapping(address => bool) public supportedTokens;

    event FundsWithdrawn(address indexed token, uint256 platformShare, uint256 merchantShare);
    event PlatformFeeChanged(uint256 newPlatformFee);
    event TokenStatusChanged(address indexed token, bool isSupported);
    event PlatformAddressChanged(address newPlatform);

    /// @notice Ensures that only the platform can call a function
    modifier onlyPlatform() {
        require(msg.sender == platform, "MFS: Only platform can call");
        _;
    }

    /// @notice Ensures that only the merchant or platform can call a function
    modifier onlyAuthorized() {
        require(msg.sender == merchant || msg.sender == platform, "MFS: Not authorized");
        _;
    }

    /// @param _merchant Address of the merchant
    /// @param _platform Address of the platform
    /// @param _platformFee Initial platform fee in basis points
    constructor(address _merchant, address _platform, uint256 _platformFee, address initialOwner) Ownable(initialOwner) {
        require(_merchant != address(0) && _platform != address(0), "MFS: Zero address");
        require(_platformFee <= 10000, "MFS: Fee exceeds 100%");
        merchant = _merchant;
        platform = _platform;
        platformFee = _platformFee;
    }

    /// @notice Adds or removes a token from the supported list
    /// @param _tokenAddress Address of the token
    /// @param _isSupported Whether the token should be supported
    function setTokenSupport(address _tokenAddress, bool _isSupported) external onlyPlatform {
        require(_tokenAddress != address(0), "MFS: Invalid token");
        supportedTokens[_tokenAddress] = _isSupported;
        emit TokenStatusChanged(_tokenAddress, _isSupported);
    }

    /// @notice Withdraws funds, splitting them between platform and merchant
    /// @param _tokenAddress Address of the token to withdraw
    function withdrawFunds(address _tokenAddress) external onlyAuthorized nonReentrant {
        require(supportedTokens[_tokenAddress], "MFS: Unsupported token");
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "MFS: No funds");

        uint256 platformShare = (balance * platformFee) / 10000;
        uint256 merchantShare = balance - platformShare;

        require(token.transfer(platform, platformShare), "MFS: Platform transfer failed");
        require(token.transfer(merchant, merchantShare), "MFS: Merchant transfer failed");

        emit FundsWithdrawn(_tokenAddress, platformShare, merchantShare);
    }

    /// @notice Sets a new platform fee
    /// @param _platformFee New platform fee in basis points
    function setPlatformFee(uint256 _platformFee) external onlyPlatform {
        require(_platformFee <= 10000, "MFS: Fee exceeds 100%");
        platformFee = _platformFee;
        emit PlatformFeeChanged(_platformFee);
    }

    /// @notice Changes the platform address
    /// @param _newPlatform Address of the new platform
    function changePlatform(address _newPlatform) external onlyOwner {
        require(_newPlatform != address(0), "MFS: Zero address");
        platform = _newPlatform;
        emit PlatformAddressChanged(_newPlatform);
    }
}