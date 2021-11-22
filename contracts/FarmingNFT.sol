pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

import "./ClubNFT.sol";
import "./INFTConnector.sol";

contract FarmingNFT is ClubNFT {

    mapping(uint256 => FarmingData) public farmingData; //tokenId => Data

    mapping(address => address) public connectors; //Mapping asset => connector

    mapping(address => uint256) public totalShares;

    struct FarmingData {
        address asset;
        uint256 shares;
        uint256 alreadyWithdrawnPerShare;
    }

    function afterMint(uint256 tokenId, address asset, uint256 amount) internal override {

        FarmingData storage data = farmingData[tokenId];
        INFTConnector connector = INFTConnector(connectors[asset]);

        data.asset = asset;
        data.alreadyWithdrawnPerShare = connector.totalRewardsPerShare() * 1e18 / totalShares[asset];
        totalShares[asset] += amount;
        data.shares = amount;

        //asset.transferFrom(msg.sender, this, amount) is already executed in super function
        connector.invest(amount);

    }

    function withdrawRewards(uint256 _tokenId) public {

        FarmingData storage data = farmingData[_tokenId];
        INFTConnector connector = INFTConnector(connectors[data.asset]);
        uint256 rewardsPerShare = connector.totalRewardsPerShare();
        uint256 amount = (rewardsPerShare - data.alreadyWithdrawnPerShare) * data.shares;
        data.alreadyWithdrawnPerShare = rewardsPerShare;
        _withdraw(data.asset, amount);

    }

    function withdrawAllRewards(address asset) public {
        uint256 length = this.balanceOf(msg.sender);
        INFTConnector connector = INFTConnector(connectors[asset]);
        uint256 rewardsPerShare = connector.totalRewardsPerShare();
        uint256 sum = 0;

        for(uint256 i = 0 ; i < length ; i++){

            uint256 tokenId = this.tokenOfOwnerByIndex(msg.sender, i);
            FarmingData storage data = farmingData[tokenId];
            sum += (rewardsPerShare - data.alreadyWithdrawnPerShare) * data.shares;
            data.alreadyWithdrawnPerShare = rewardsPerShare;
        }
        _withdraw(asset, sum);
    }

    function _withdraw(address asset, uint256 amount) internal {
        INFTConnector connector = INFTConnector(connectors[asset]);
        connector.withdraw(amount, msg.sender);
    }

    modifier validConnector(address asset) {
        require(connectors[asset] != address(0), "Connector not set");
        _;
    }

    //Operator functions

    function setupMigration(address asset) external onlyOwner {

        INFTConnector connector = INFTConnector(connectors[asset]);
        connector.drainToPool();

        connectors[asset] = address(0);
    }

    function migrate(address asset, address _connector) external onlyOwner {

        INFTConnector connector = INFTConnector(_connector);
        uint256 balance = IERC20(asset).balanceOf(address(this));
        uint256 shares = totalShares[asset];
        IERC20(asset).approve(_connector, ~uint(0));
        connector.migrate(shares, balance - shares);
        
        connectors[asset] = _connector;
    }

    function setConnector(address asset, address connector) external onlyOwner {
        IERC20(asset).approve(connector, ~uint(0));
        connectors[asset] = connector;
    }

    //Drainerc20

}