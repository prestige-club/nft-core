pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

import "./ConnectorBase.sol";
import "./INFTConnector.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ShareAwareConnector is ConnectorBase, INFTConnector{

    using SafeERC20 for IERC20;

    address asset;

    constructor(address _asset) public {
        asset = _asset;
    }

    uint256 totalShares;
    uint256 withdrawn;
    uint256 payedOut; //Sum of tokens payed out to users. Should always be less or equal to withdrawn

    function invest(uint256 amount) public override onlyFarmingContract {

        IERC20(asset).safeTransferFrom(msg.sender, address(this, amount));
        (uint256 compounded, _) = _deposit(amount);
        totalShares += amount;
        withdrawn += compounded;

    }
    
    function withdraw(uint256 amount, address to) external override onlyFarmingContract {

        (uint256 compounded, _) = _deposit(amount);
        withdrawn += compounded;
        payedOut += amount;
        IERC20(asset).safeTransfer(to, amount);
        require(payedOut <= withdrawn, "More payed out than withdrawn");
        require(_balance() >= totalShares, "Balance drained");

    }

    function totalRewardsPerShare() external override view returns (uint256) {

        return (withdrawn + pendingRewards()) * 1e18 / totalShares;

    }

    function drainToPool() external override onlyFarmingContract {
        
        _withdraw(_balance() + pendingRewards());
        uint256 balance = IERC20(asset).balanceOf(address(this));
        IERC20(asset).transfer(msg.sender, balance);

    }

    function migrate(uint256 amount, uint256 provisions) external override {

    }

    //TODO Add Emergency Withdrawn functionality

    // function pendingRewards() external view returns (uint256);
    // function updateRewards() external returns (uint256); //Returns rewardsPerShare

    //All these functions return 2 Values: 
    //uint256 amountCompounded, uint256 amountWithdrawn
    //Should throw if the operation would result in an deposit/withdrawn different "amount".
    function _withdraw(uint256 amount) internal virtual returns (uint256, uint256);
    function _deposit(uint256 amount) internal virtual returns (uint256, uint256);

    //Returns current invested balance in connector
    function _balance() internal virtual returns (uint256);


}