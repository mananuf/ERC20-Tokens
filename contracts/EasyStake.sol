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
        Pools poolType;
        bool claimed;
    }

    mapping(address => Stake) public stakes;

    enum Pools { oneWeekPool, twoWeeksPool, threeWeeksPool }

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
        duration[1] =  block.timestamp + (14 * 24 * 60 * 60); // 2 weeks
        duration[2] =    block.timestamp + (21 * 24 * 60 * 60); // 3 weeks


        uint8 numberOfNft = nftForPool[_poolId];
        uint256 _finishesAt = duration[_poolId];
        Pools _poolType = Pools(_poolId);

        stakes[msg.sender] = Stake({
            amountStaked: _amount,
            stakedAt: block.timestamp,
            finishesAt: _finishesAt,
            nftReward: numberOfNft,
            claimed: false,
            poolType: _poolType
        });

        emit Staked(msg.sender, _amount, _poolId);
    }

    function claimReward(bool _convertTokenToNft) external {
        // require(stakes[msg.sender].claimed == false, "Claimed Already");
        uint8 numberOfNftToClaim;
        uint8 nftReward = stakes[msg.sender].nftReward;

        if(block.timestamp >= stakes[msg.sender].finishesAt) {
            numberOfNftToClaim = stakes[msg.sender].nftReward;
            stakes[msg.sender].claimed = true;

            if (_convertTokenToNft) {
                uint256 nftId = getNftIdForPool(stakes[msg.sender].poolType);
                nftToken.mint(msg.sender, nftId, numberOfNftToClaim, "");
            } else {
                uint rewardTokens = (nftReward * numberOfTokensPerReward);
                // + stakes[msg.sender].amountStaked;
                easyToken.transfer(msg.sender, rewardTokens);
            }
        } else {
            revert TimeHasNotEllapsed();
        }

        emit RewardClaimed(msg.sender, nftReward, _convertTokenToNft);
    }



    function convertNftBackToTokens() external {
        //get minted NFt type and convert back to tokens
    }

    function getEasyStakeBalance() external view returns (uint) {
        return easyToken.balanceOf(address(this));
    }

    function getNftIdForPool(Pools pool) internal pure returns (uint256) {
        if (pool == Pools.oneWeekPool) return 1;
        if (pool == Pools.twoWeeksPool) return 2;
        if (pool == Pools.threeWeeksPool) return 3;
        revert("Invalid pool type");
    }

    // dev function for test purpose
    function getNftId(Pools pool) external pure returns (uint256) {
        return getNftIdForPool(pool);
    }
}