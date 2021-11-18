pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

interface INFTConnector{

    function invest(uint256 amount) external;
    function pendingRewards() external view returns (uint256);
    function totalRewardsPerShare() external view returns (uint256);
    function updateRewards() external returns (uint256); //Returns rewardsPerShare
    function withdraw(uint256 amount, address to) external;
    function drainToPool() external;
    function migrate(uint256 amount, uint256 provisions) external;

}