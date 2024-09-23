//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IERC20.sol";
import "./interface/IERC1155Mintable.sol";
import "hardhat/console.sol";

contract EasyStake {

    address public owner;
    IERC20 public easyToken;
    IERC1155Mintable public nftToken; 
    uint8 constant numberOfTokensPerReward = 25;

    struct Stake {
        uint256 amountStaked;
        uint256 stakedAt;
        uint256 finishesAt;
        uint8 nftReward;
        bool claimed;
    }

    mapping(uint8 => mapping(address => Stake)) public pools;

    error TimeHasNotEllapsed();

    // Events to track staking actions
    event Staked(address indexed user, uint256 amount, uint8 poolId);
    event RewardClaimed(address indexed user, uint8 nft, bool convertTokenToNft);

    constructor (address _tkenAddress, address _nftAddress) {
        owner = msg.sender;
        easyToken = IERC20(_tkenAddress);
        nftToken = IERC1155Mintable(_nftAddress);
    }

    function stake(uint _amount, uint8 _poolId) external {
        require(_poolId <= 2, "invalid pool");
        require(easyToken.balanceOf(msg.sender) > _amount, "insufficient tokens");

        easyToken.transferFrom(msg.sender, address(this), _amount);

        uint8[3] memory nftForPool = [1,2,3];
        uint256[3] memory duration;
        duration[0] = block.timestamp + (7 * 24 * 60 * 60); // 1 week
        duration[1] = block.timestamp + (14 * 24 * 60 * 60); // 2 weeks
        duration[2] = block.timestamp + (21 * 24 * 60 * 60); // 3 weeks


        uint8 numberOfNft = nftForPool[_poolId];
        uint256 _finishesAt = duration[_poolId];

        pools[_poolId][msg.sender] = Stake({
            amountStaked: _amount,
            stakedAt: block.timestamp,
            finishesAt: _finishesAt,
            nftReward: numberOfNft,
            claimed: false
        });

        emit Staked(msg.sender, _amount, _poolId);
    }

    function claimReward(bool _convertTokenToNft, uint8 _poolId) external {
        uint8 numberOfNftToClaim;
        uint8 nftReward = pools[_poolId][msg.sender].nftReward;

        if(block.timestamp >= pools[_poolId][msg.sender].finishesAt) {
            numberOfNftToClaim = pools[_poolId][msg.sender].nftReward;
            pools[_poolId][msg.sender].claimed = true;

            if (_convertTokenToNft) {
                nftToken.mint(msg.sender, 1, nftReward, "easy stake pool");
            } else {
                uint rewardTokens = (nftReward * numberOfTokensPerReward);
                easyToken.transfer(msg.sender, rewardTokens);
            }
        } else {
            revert TimeHasNotEllapsed();
        }

        emit RewardClaimed(msg.sender, nftReward, _convertTokenToNft);
    }

    function getUserStakeDetails(uint8 _poolId, address _userAddress) external view {
        pools[_poolId][_userAddress];
    }

    function getEasyStakeBalance() external view returns (uint) {
        return easyToken.balanceOf(address(this));
    }
}