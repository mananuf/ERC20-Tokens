// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IEasyStake {
    function stake(uint _amount, uint8 _poolId) external;
}