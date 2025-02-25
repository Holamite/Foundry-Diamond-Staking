// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";

contract StakingFacet {
    LibAppStorage.PoolDataReturnedType poolDataReturnedType;
    LibAppStorage.Pool pool;

    IERC20 private stakeToken;
    IERC20 private rew
    uint256 public id;

    mapping(uint256 => pool) internal pools;

    event poolCreated(
        uint256 PoolID,
        uint256 poolReward,
        uint256 at,
        address by
    );
    event Stake(
        uint256 poolID,
        address indexed account,
        uint256 indexed amount,
        uint256 at
    );
    event Unstake(
        uint256 poolID,
        address indexed account,
        uint256 indexed amount,
        uint256 at
    );
    event RewardClaim(
        uint256 poolID,
        address indexed account,
        uint256 indexed amount,
        uint256 at
    );

    constructor(address _stakeTokenAddress, address _rewardTokenAddress) {
        stakeToken = IERC20(_stakeTokenAddress);
        rewardToken = IERC20(_rewardTokenAddress);
    }

    function createPool(uint256 _rewardRate) public {
        // withdrawing the 100 pool reward token from the pool creator
        rewardToken.transferFrom(msg.sender, address(this), 100E18);
        pool = pools[id];
        pool.rewardRate = _rewardRate;
        pool.APY = 120; // 120% APY
        pool.rewardReserve = 100E18;
        emit poolCreated(id, 100E18, block.timestamp, msg.sender);
        id++;
    }

    function getPoolByID(
        uint256 _id
    ) external view returns (LibAppStorage.PoolDataReturnedType memory _pool) {
        _pool = PoolDataReturnedType(
            pools[_id].totalStakers,
            pools[_id].totalStaked,
            pools[_id].rewardReserve,
            pools[_id].rewardRate,
            pools[_id].APY
        );
    }

    function stake(uint256 _poolID, uint256 _amount) external {
        pool = pools[_poolID];
        stakeToken.transferFrom(msg.sender, address(this), _amount);
        // calculate the user's reward up until this moment and add it to storedReward;
        uint256 userPreviousBalance = pool.stakersBalances[msg.sender];
        if (userPreviousBalance > 0) {
            uint256 previousReward = _getUserReward(_poolID, msg.sender);
            pool.stakerStoredReward[msg.sender] = previousReward;
        }
        // increment stakers if their previous balance is 0, it signifies new staker,
        if (userPreviousBalance == 0) {
            pool.totalStakers++;
        }

        pool.stakersBalances[msg.sender] += _amount;
        pool.totalStaked += _amount;
        pool.stakerRewardPerSec[msg.sender] = _calculateRewardperSecond(
            _poolID,
            pool.stakersBalances[msg.sender]
        );
        pool.stakerLastUpdatedTime[msg.sender] = block.timestamp;
        emit Stake(_poolID, msg.sender, _amount, block.timestamp);
    }

    function _calculateRewardperSecond(
        uint256 _poolID,
        uint256 _stakedAmount
    ) private view returns (uint256 _rewardPerSecond) {
        uint256 secInDay = 1 days;
        _rewardPerSecond =
            ((_stakedAmount * pools[_poolID].rewardRate) / secInDay) *
            (pools[_poolID].APY / 100);
    }

    function _getUserReward(
        uint256 _poolID,
        address _account
    ) internal view returns (uint256 _userReward) {
        uint256 userRewardPerSec = pools[_poolID].stakerRewardPerSec[_account];
        uint256 timeElapsed = block.timestamp -
            pools[_poolID].stakerLastUpdatedTime[_account];
        _userReward =
            (userRewardPerSec * timeElapsed) +
            pools[_poolID].stakerStoredReward[_account];
    }

    function getUserClaimableReward(
        uint256 _poolID,
        address _staker
    ) external view returns (uint _reward) {
        _reward = _getUserReward(_poolID, _staker);
    }

    function unstake(uint256 _poolID) external {
        pool = pools[_poolID];
        uint256 balance = pool.stakersBalances[msg.sender];
        require(
            balance > 0,
            "Staking pool contract: You do not have any token staked in this pool"
        );
        uint256 reward = _getUserReward(_poolID, msg.sender);
        pool.stakersBalances[msg.sender] = 0;
        pool.totalStakers--;
        pool.stakerStoredReward[msg.sender] = 0;
        pool.totalStaked -= balance;
        pool.rewardReserve -= reward;
        stakeToken.transfer(msg.sender, balance);
        rewardToken.transfer(msg.sender, reward);
        emit Unstake(_poolID, msg.sender, balance, block.timestamp);
    }

    function claimReward(uint256 _poolID) external {
        pool = pools[_poolID];
        uint256 reward = _getUserReward(_poolID, msg.sender);
        require(
            reward > 0,
            "Staking pool contract: You do not have any reward to be claimed in this pool"
        );
        pool.stakerLastUpdatedTime[msg.sender] = block.timestamp;
        pool.rewardReserve -= reward;
        pool.stakerStoredReward[msg.sender] = 0;
        require(rewardToken.transfer(msg.sender, reward));
        emit RewardClaim(_poolID, msg.sender, reward, block.timestamp);
    }

    function getUserStakeBalance(
        uint256 _poolID,
        address _account
    ) external view returns (uint256 _stake) {
        _stake = pools[_poolID].stakersBalances[_account];
    }

    function getUserPoolRewardPerSec(
        uint256 _poolID,
        address _account
    ) external view returns (uint256 _rewardPerSecond) {
        _rewardPerSecond = pools[_poolID].stakerRewardPerSec[_account];
    }
}
