// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract xUSD is ERC20("Hypermax USD", "xUSD"), Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public totalDebt;

    mapping(address => bool) public allowedAsset;
    mapping(address => bool) public whitelist;

    constructor() Ownable(msg.sender) {
        whitelist[msg.sender] = true;
    }

    /**
     * @dev Mint xUSD recording debt
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
        totalDebt += amount;
    }

    /**
     * @dev Burn xUSD to repay debt
     */
    function burn(uint256 amount) external nonReentrant {
        address msgSender = _msgSender();

        if (amount >= totalDebt) {
            _burn(msgSender, totalDebt);
            totalDebt = 0;
        } else {
            _burn(msgSender, amount);
            totalDebt -= amount;
        }
    }

    /**
     * @dev Override totalSupply to exclude debt
     */
    function totalSupply() public view override returns (uint256) {
        uint256 baseSupply = super.totalSupply();
        if (baseSupply >= totalDebt) {
            return baseSupply - totalDebt;
        }
        return 0; // never happen
    }

    /**
     * @dev Owner can add assets allowed for PSM
     */
    function addAsset(address asset) external onlyOwner {
        allowedAsset[asset] = true;
    }

    /**
     * @dev Anyone deposits allowed asset to mint xUSD (asset-backed)
     */
    function psmDeposit(address asset, uint256 amount) external nonReentrant {
        require(allowedAsset[asset], "Asset not allowed");

        address msgSender = _msgSender();

        IERC20(asset).safeTransferFrom(msgSender, address(this), amount);
        _mint(
            msgSender,
            (amount * 10 ** decimals()) /
                (10 ** IERC20Metadata(asset).decimals())
        );
    }

    /**
     * @dev Whitelisted users burn xUSD to redeem underlying asset
     */
    function psmRedeem(address asset, uint256 amount) external nonReentrant {
        require(allowedAsset[asset], "Asset not allowed");

        address msgSender = _msgSender();
        require(whitelist[msgSender], "Not whitelisted");

        _burn(msgSender, amount);
        IERC20(asset).safeTransfer(
            msgSender,
            (amount * 10 ** IERC20Metadata(asset).decimals()) /
                (10 ** decimals())
        );
    }

    /**
     * @dev Owner can manage redemption whitelist
     */
    function addWhitelist(address user) external onlyOwner {
        whitelist[user] = true;
    }

    function removeWhitelist(address user) external onlyOwner {
        whitelist[user] = false;
    }
}
