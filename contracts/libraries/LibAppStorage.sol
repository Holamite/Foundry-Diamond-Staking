// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibAppStorage {
    struct Layout {
        uint256 currentNo;
        string name;
    }

    struct Pool {
        uint256 totalStakers;
        uint256 totalStaked;
        uint256 rewardReserve;
        uint256 rewardRate; // daily for example
        uint256 APY; // Annual Percentage Yield
        mapping(address => uint256) stakersBalances;
        mapping(address => uint256) stakerRewardPerSec;
        mapping(address => uint256) stakerStoredReward;
        mapping(address => uint256) stakerLastUpdatedTime;
    }

    struct PoolDataReturnedType {
        uint256 totalStakers;
        uint256 totalStaked;
        uint256 rewardReserve;
        uint256 rewardRate;
        uint256 APY;
    }
}
