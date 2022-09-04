// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "solmate/utils/FixedPointMathLib.sol";

import "./interfaces/IWETH.sol";

/// @title A kind of opinionated multi-assets lockable tokenized vault
/// @author oba <obatirou@gmail.com>
/// @notice The vault is tokenized and withdrawal of assets can be locked
/// @dev Withdrawal functions are callable only by tokens owners
///      Configuration fonctions are only callable by the owner of the contract
contract CommonPot is Ownable, ERC20 {
    using SafeTransferLib for ERC20;
    using SafeERC20 for IERC20;

    /// @dev Minimum number of days before a lock can happen
    uint256 public immutable minDaysDelay;
    /// @dev WETH interface
    IWETH public immutable weth;
    /// @dev Timestamp at which assets will be withdrawble
    uint256 lock;
    /// @dev Timestamp to begin count minDaysDelay before a new lock
    uint256 minDaysDelayTimestamp;
    /// @dev Maximum whitelisted assets
    uint8 maxAssets;
    /// @dev Actual number of whitelisted assets
    uint8 nbAssets;
    /// @dev Mapping for whitelisted assets
    mapping(address => bool) public whitelistedAsset;

    /// @notice Mints ERC20 tokens to owner
    ///         Sets minDaysDelay, maxAssets and WETH
    constructor(
        uint8 _minDaysDelay,
        uint8 _maxAssets,
        address _weth
    ) ERC20("CommonPot", "CMNP", 18) {
        require(_maxAssets != 0, "Max assets == 0");
        _mint(msg.sender, 100 * 10 ^ 18);
        minDaysDelay = _minDaysDelay;
        maxAssets = _maxAssets;
        weth = IWETH(_weth);
    }

    /// @dev Only token owner can call withdraw functions of this contract
    modifier onlyTokenOwner() {
        require(balanceOf[msg.sender] != 0, "Not token owner");
        _;
    }

    /// @dev Always deposit ETH to simplify accounting and avoid ETH stuck in contract
    receive() external payable {
        weth.deposit{ value: msg.value }();
    }

    /// @notice PrepareLock is part of a system to allow token owners to have time to withdraw their
    ///         share before a new lock. We take the timestamp to start counting for minDaysDelay
    ///         before locking.
    /// @dev Take a timestamp to begin count minDaysDelay before relock can happen
    function prepareLock() external onlyOwner {
        require(lock < block.timestamp, "Locked");
        require(minDaysDelayTimestamp == 0 || minDaysDelayTimestamp < lock, "Lock already prepared");
        minDaysDelayTimestamp = block.timestamp;
    }

    /// @notice Set the lock but require prepareLock was called before
    /// @dev Set lock timestamp
    /// @param nbSeconds Number of seconds of locking assets in contract
    function setLock(uint256 nbSeconds) external onlyOwner {
        require(minDaysDelayTimestamp + minDaysDelay * 1 days < block.timestamp, "Lock not prepared");
        unchecked {
            lock = block.timestamp + nbSeconds;
        }
    }

    /// @dev Adds an asset to the whitelisted ones
    /// @param asset Asset to whitelist
    function addAsset(address asset) external onlyOwner {
        require(nbAssets < maxAssets, "Max assets reached");
        unchecked {
            ++nbAssets;
        }
        whitelistedAsset[asset] = true;
    }

    /// @dev Adds assets to the whitelisted ones
    /// @param assets List of asset to whitelist
    function addAssets(address[] calldata assets) external onlyOwner {
        uint256 length = assets.length;
        uint8 _nbAssets = nbAssets;
        uint8 _maxAssets = maxAssets;
        unchecked {
            for (uint256 i; i < length; ++i) {
                require(_nbAssets < _maxAssets, "Max assets reached");
                ++_nbAssets;
                whitelistedAsset[assets[i]] = true;
            }
        }
        nbAssets = _nbAssets;
    }

    /// @dev Withdraw asset according to amount of shares owner have
    /// @param asset Asset to withdraw
    /// @param shares Number of shares of the vault
    function withdrawFund(IERC20 asset, uint256 shares) external onlyTokenOwner {
        require(lock < block.timestamp, "Locked");
        require(whitelistedAsset[address(asset)], "Asset not whitelisted");
        uint256 currentTotalSupply = totalSupply;
        _burn(msg.sender, shares);
        asset.safeTransfer(
            msg.sender,
            FixedPointMathLib.mulDivDown(asset.balanceOf(address(this)), shares, currentTotalSupply)
        );
    }

    /// @dev Withdraw asset according to amount of shares owner have
    /// @param assets List of asset to withdraw
    /// @param shares Number of shares of the vault
    function withdrawFunds(IERC20[] calldata assets, uint256 shares) external onlyTokenOwner {
        require(lock < block.timestamp, "Locked");
        uint256 length = assets.length;
        uint256 currentTotalSupply = totalSupply;
        _burn(msg.sender, shares);
        for (uint256 i; i < length; ++i) {
            IERC20 asset = assets[i];
            require(whitelistedAsset[address(asset)], "Asset not whitelisted");
            asset.safeTransfer(
                msg.sender,
                FixedPointMathLib.mulDivDown(asset.balanceOf(address(this)), shares, currentTotalSupply)
            );
        }
    }
}
