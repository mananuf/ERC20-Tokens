import { ethers } from "hardhat";

async function main() {
    const MyTokenAddress = "0xA48331133465F9bC5c05dBEF2B0c4026ca52779b";
    const tokenAddress = await ethers.getContractAt("IERC20", MyTokenAddress);

    const StakingPoolContractAddress = "0xE7C0fC80EB163258e58D56D98b3d58bD2Ec878Cf";
    const stakingPool = await ethers.getContractAt("IEasyStake", StakingPoolContractAddress);

    // Approve savings contract to spend token
    const approvalAmount = ethers.parseUnits("1000", 18);

    const approveTx = await tokenAddress.approve(stakingPool, approvalAmount);
    approveTx.wait();

    // const contractBalanceBeforeDeposit = await stakingPool.getContractBalance();
    // console.log("Contract balance before :::", contractBalanceBeforeDeposit);

    const stakeAmount = ethers.parseUnits("150", 18);
    const depositTx = await stakingPool.stake(stakeAmount, 1);

    // console.log(depositTx);

    depositTx.wait();

    // const contractBalanceAfterDeposit = await stakingPool.getContractBalance();

    // console.log("Contract balance after :::", contractBalanceAfterDeposit);
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});