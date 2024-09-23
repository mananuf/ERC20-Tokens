import { ethers } from "hardhat";

async function main() {
    const [signer] = await ethers.getSigners();
    const signerAddress = await signer.getAddress();

    const EasyTokenAddress = "0xA48331133465F9bC5c05dBEF2B0c4026ca52779b";
    const easyToken = await ethers.getContractAt("IERC20", EasyTokenAddress);

    const EasyStakeContractAddress = "0xE7C0fC80EB163258e58D56D98b3d58bD2Ec878Cf";
    const easyStake = await ethers.getContractAt("IEasyStake", EasyStakeContractAddress);

    // Approve savings contract to spend token
    const approvalAmount = ethers.parseUnits("1000", 18);

    const approveTx = await easyToken.approve(easyStake, approvalAmount);
    approveTx.wait();

    // Stake Tokens
    const stakeAmount = ethers.parseUnits("150", 18);
    const poolId = 1;
    const stakeTx = await easyStake.stake(stakeAmount, poolId);
    console.log(`Staking ${ethers.formatUnits(stakeAmount, 18)} tokens in pool ${poolId}...`);

    await stakeTx.wait();

    console.log("Staking successful.");
    
    // claim rewards
    const convertToNft = true;
    try {
        const claimTx = await easyStake.claimReward(convertToNft, poolId);
        console.log("Claiming rewards...");
        await claimTx.wait();
        console.log("Rewards claimed successfully.");
    } catch (error) {
        console.log(error);
    }
    
    // Get EasyStake Contract's Token Balance
    const contractBalance = await easyStake.getEasyStakeBalance();
    console.log(`EasyStake Contract Balance: ${ethers.formatUnits(contractBalance, 18)} EASY`);

    // Additional: Get User's EasyToken Balance
    const userBalance = await easyToken.balanceOf(signer.address);
    console.log(`Your EasyToken Balance: ${ethers.formatUnits(userBalance, 18)} EASY`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});