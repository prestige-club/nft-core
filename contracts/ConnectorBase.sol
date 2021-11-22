pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ConnectorBase is Ownable {

    address public farmingContract;

    modifier onlyFarmingContract() {
        require(msg.sender == farmingContract || msg.sender == owner(), "Caller not authorized");
        _;
    }

    function setFarmingContact(address _farmingContract) public onlyOwner {
        require(_farmingContract != address(0), "Zero Address not a valid farming Contract");
        farmingContract = _farmingContract;
    }

}