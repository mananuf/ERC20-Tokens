import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import hre from "hardhat";
  
  describe("EasyStake", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
     
    async function deployToken() {
      // Contracts are deployed using the first signer/account by default
      // ethers.getSigners() returns 20 account addresses
      //unpack the first two accounts and save accordingly
      const [tokenOwner, otherAccount] = await hre.ethers.getSigners();
  
      //get contract to deploy
      const erc20Token = await hre.ethers.getContractFactory("EasyToken");
      const EasyToken = await erc20Token.deploy();

    //   by default, it implicitly deploys with the first account
    //   you can explicitly deploy by specifing account address to use

    //   const token = await erc20Token.connect(otherAccount).deploy();
  
      return { EasyToken, tokenOwner };
    }

    async function deployNftToken() {
      // Contracts are deployed using the first signer/account by default
      // ethers.getSigners() returns 20 account addresses
      //unpack the first two accounts and save accordingly
      const [nftOwner, otherAccount] = await hre.ethers.getSigners();
  
      //get contract to deploy
      const erc1155Token = await hre.ethers.getContractFactory("NFT");
      const nftToken = await erc1155Token.deploy();

    //   by default, it implicitly deploys with the first account
    //   you can explicitly deploy by specifing account address to use
  
      return { nftToken, nftOwner };
    }
  
    async function deployEasyStake() {
      const [owner, otherAccount] = await hre.ethers.getSigners();
  
      const { EasyToken } = await loadFixture(deployToken);
      const { nftToken } = await loadFixture(deployNftToken);
  
      const EasyStakeContract = await hre.ethers.getContractFactory("EasyStake");
      const EasyStake = await EasyStakeContract.deploy(EasyToken, nftToken);
  
  
      return { EasyStake, owner, otherAccount, EasyToken, nftToken };
    }
  
    describe("Test for contract deployment and owner", function () {
      it("Should pass if owner is correct", async function () {
        const { EasyStake, owner, otherAccount} = await loadFixture(deployEasyStake);
  
        expect(await EasyStake.owner()).to.equal(owner);
      });
  
      it("Should fail if owner is incorrect", async function () {
        const { EasyStake, owner, otherAccount  } = await loadFixture(deployEasyStake);
  
        expect(await EasyStake.owner()).to.not.eq(otherAccount);
      });
      
    });
  
    describe("Test stake function", function () {
      it("Should revert with 'invalid pool' if wrong poolId is passed as argument" , async function () {
        const { EasyStake, owner, otherAccount  } = await loadFixture(deployEasyStake);
  
        await expect(EasyStake.stake(1000, 4)).to.be.revertedWith("invalid pool")
      });
  
      it("Should pass if all parameters are set correctly" , async function () {
        // deploy contracts
        const { EasyStake, owner, otherAccount, EasyToken } = await loadFixture(deployEasyStake);


        // expect balance of otherAccount to be zero
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(0);

        const amountTransferred = 1000;


        // Transfer to user (await the transfer)
        await EasyToken.transfer(otherAccount.address, amountTransferred);

        // expect balance of otherAccount to be eqaul to new amount transferred
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(amountTransferred);

        // Approve EasyStake contract to spend otherAccount's tokens
        await EasyToken.connect(otherAccount).approve(EasyStake.target, amountTransferred);

        // Check that the staking contract has allowance
        // expect(await EasyToken.allowance(otherAccount.address, EasyStake.target)).to.equal(amountTransferred);


        const stakedAmount = 500;
        const poolId = 0;

        // //ACT
        await expect(EasyStake.connect(otherAccount).stake(stakedAmount, poolId)).to.emit(EasyStake, 'Staked').withArgs(otherAccount.address, stakedAmount, poolId);
      })

      it("Should deduct balance of stake user and add to balance of EasyStake contract correctly" , async function () {
        // deploy contracts
        const { EasyStake, owner, otherAccount, EasyToken } = await loadFixture(deployEasyStake);


        // expect balance of otherAccount to be zero
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(0);

        const amountTransferred = 1000;


        // Transfer to user (await the transfer)
        await EasyToken.transfer(otherAccount.address, amountTransferred);

        // expect balance of otherAccount to be eqaul to new amount transferred
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(amountTransferred);

        // Approve EasyStake contract to spend otherAccount's tokens
        await EasyToken.connect(otherAccount).approve(EasyStake.target, amountTransferred);


        const stakedAmount = 500;
        const poolId = 0;

        // //ACT
        await expect(EasyStake.connect(otherAccount).stake(stakedAmount, poolId)).to.emit(EasyStake, 'Staked').withArgs(otherAccount.address, stakedAmount, poolId);
  
        //test that balance of user has decreaseed by staking amount
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(amountTransferred - stakedAmount);

        // test that balance of EasyStake contract has increased
        expect(await EasyToken.balanceOf(EasyStake.target)).to.equal(stakedAmount);

      })

      it("Should revert with 'insufficient tokens' when stake amount is greater than user balance" , async function () {
        // deploy contracts
        const { EasyStake, owner, otherAccount, EasyToken } = await loadFixture(deployEasyStake);

        // expect balance of otherAccount to be zero
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(0);

        const stakedAmount = 1001;
        const poolId = 0;

        // //ACT
        await expect(EasyStake.connect(otherAccount).stake(stakedAmount, poolId)).to.be.revertedWith("insufficient tokens");
      })

      it("Should revert with 'InsufficientAllowance error' when spending allowance is insufficient" , async function () {
        // deploy contracts
        const { EasyStake, owner, otherAccount, EasyToken } = await loadFixture(deployEasyStake);

        // expect balance of otherAccount to be zero
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(0);

        const stakedAmount = 500;
        const poolId = 0;
        const amountTransferred = 1000;

        // Transfer to user (await the transfer)
        await EasyToken.transfer(otherAccount.address, amountTransferred);

        // expect balance of otherAccount to be amountTransferred
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(amountTransferred);

        // Approve EasyStake contract to spend otherAccount's tokens
        await EasyToken.connect(otherAccount).approve(EasyStake.owner(), amountTransferred);

        // //ACT
        await expect(EasyStake.connect(otherAccount).stake(stakedAmount, poolId))
                        .to.be.revertedWithCustomError(EasyToken, "InsufficientAllowance")
                        .withArgs(EasyStake.target, 0, stakedAmount);
      })

      it("Should create oneWeekPool with expected parameters" , async function () {
        // deploy contracts
        const { EasyStake, owner, otherAccount, EasyToken } = await loadFixture(deployEasyStake);

        // expect balance of otherAccount to be zero
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(0);

        const amountTransferred = 1000;

        // Transfer to user (await the transfer)
        await EasyToken.transfer(otherAccount.address, amountTransferred);

        // expect balance of otherAccount to be eqaul to new amount transferred
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(amountTransferred);

        // Approve EasyStake contract to spend otherAccount's tokens
        await EasyToken.connect(otherAccount).approve(EasyStake.target, amountTransferred);

        const stakedAmount = 500;
        const poolId = 0;

        // //ACT
        await expect(EasyStake.connect(otherAccount).stake(stakedAmount, poolId)).to.emit(EasyStake, 'Staked').withArgs(otherAccount.address, stakedAmount, poolId);

        const stake = await EasyStake.pools(poolId, otherAccount.address);

        const currentTimestamp = (await hre.ethers.provider.getBlock()).timestamp;
        const expectedFinishAt = currentTimestamp + (7 * 24 * 60 * 60); // 7 days duration

        // Check the stake details
        expect(stake.amountStaked).to.equal(stakedAmount);
        expect(stake.stakedAt).to.be.closeTo(currentTimestamp, 2); // Allow 2 seconds discrepancy
        expect(stake.finishesAt).to.equal(expectedFinishAt);
        expect(stake.nftReward).to.equal(1); // 1weekPool gives 1 NFTs
        expect(stake.claimed).to.equal(false);
      })

      it("Should create twoWeeksPool with expected parameters" , async function () {
        // deploy contracts
        const { EasyStake, owner, otherAccount, EasyToken } = await loadFixture(deployEasyStake);

        // expect balance of otherAccount to be zero
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(0);

        const amountTransferred = 1000;

        // Transfer to user (await the transfer)
        await EasyToken.transfer(otherAccount.address, amountTransferred);

        // expect balance of otherAccount to be eqaul to new amount transferred
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(amountTransferred);

        // Approve EasyStake contract to spend otherAccount's tokens
        await EasyToken.connect(otherAccount).approve(EasyStake.target, amountTransferred);

        const stakedAmount = 500;
        const poolId = 1; //2 weeks poolId

        // //ACT
        await expect(EasyStake.connect(otherAccount).stake(stakedAmount, poolId)).to.emit(EasyStake, 'Staked').withArgs(otherAccount.address, stakedAmount, poolId);

        const stake = await EasyStake.pools(poolId, otherAccount.address);

        const currentTimestamp = (await hre.ethers.provider.getBlock()).timestamp;
        const expectedFinishAt = currentTimestamp + (14 * 24 * 60 * 60); // 14 days duration

        // Check the stake details
        expect(stake.amountStaked).to.equal(stakedAmount);
        expect(stake.stakedAt).to.be.closeTo(currentTimestamp, 2); // Allow 2 seconds discrepancy
        expect(stake.finishesAt).to.equal(expectedFinishAt);
        expect(stake.nftReward).to.equal(2); // 2weeksPool gives 2 NFTs
        // expect(stake.poolType).to.equal(poolId);
        expect(stake.claimed).to.equal(false);
      })

      it("Should create threeWeeksPool with expected parameters" , async function () {
        // deploy contracts
        const { EasyStake, owner, otherAccount, EasyToken } = await loadFixture(deployEasyStake);

        // expect balance of otherAccount to be zero
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(0);

        const amountTransferred = 1000;

        // Transfer to user (await the transfer)
        await EasyToken.transfer(otherAccount.address, amountTransferred);

        // expect balance of otherAccount to be eqaul to new amount transferred
        expect(await EasyToken.balanceOf(otherAccount)).to.equal(amountTransferred);

        // Approve EasyStake contract to spend otherAccount's tokens
        await EasyToken.connect(otherAccount).approve(EasyStake.target, amountTransferred);

        const stakedAmount = 500;
        const poolId = 2; // 3 weeks poolId

        // //ACT
        await expect(EasyStake.connect(otherAccount).stake(stakedAmount, poolId)).to.emit(EasyStake, 'Staked').withArgs(otherAccount.address, stakedAmount, poolId);

        const stake = await EasyStake.pools(poolId, otherAccount.address);

        const currentTimestamp = (await hre.ethers.provider.getBlock()).timestamp;
        const expectedFinishAt = currentTimestamp + (21 * 24 * 60 * 60); // 21 days duration

        // Check the stake details
        expect(stake.amountStaked).to.equal(stakedAmount);
        expect(stake.stakedAt).to.be.closeTo(currentTimestamp, 2); // Allow 2 seconds discrepancy
        expect(stake.finishesAt).to.equal(expectedFinishAt);
        expect(stake.nftReward).to.equal(3); // 3weekPool gives 3 NFTs
        // expect(stake.poolType).to.equal(poolId);
        expect(stake.claimed).to.equal(false);
      })
    });

    describe("Test claimReward function", function () {

        it("Should revert if _convertTokenToNft is not a boolean", async function () {
          const { EasyStake, otherAccount } = await loadFixture(deployEasyStake);
      
          // Call claimReward with an incorrect parameter type (e.g., a number instead of a bool)
            await expect( EasyStake.connect(otherAccount).claimReward(1234, 1)).to.be.reverted;
            await expect( EasyStake.connect(otherAccount).claimReward("true", 1)).to.be.reverted;
        });
      
        it("Should revert with customError 'TimeHasNotEllapsed' if the user tries to claim reward before staking period is over", async function () {
          const { EasyStake, owner, otherAccount, EasyToken, nftToken } = await loadFixture(deployEasyStake);
      
          // Set up staking with correct parameters
          const amountTransferred = 1000;
          const stakedAmount = 500;
          const poolId = 0;
      
          // Transfer tokens and approve EasyStake to use them
          await EasyToken.transfer(otherAccount.address, amountTransferred);
          await EasyToken.connect(otherAccount).approve(EasyStake.target, stakedAmount);
      
          // Stake tokens
          await EasyStake.connect(otherAccount).stake(stakedAmount, poolId);
      
          //try to claim reward
          await expect( EasyStake.connect(otherAccount).claimReward(false, poolId)).to.be.revertedWithCustomError(EasyStake,'TimeHasNotEllapsed');
        });
      
        it("Should allow claiming reward after time has passed for 1 week pool", async function () {
          const { EasyStake, EasyToken, owner, otherAccount } = await loadFixture(deployEasyStake);
      
          const amountTransferred = 1000;
          const stakedAmount = 500;
          const poolId = 0;
      
          // Transfer tokens and approve EasyStake to use them
          await EasyToken.transfer(otherAccount.address, amountTransferred);
          await EasyToken.connect(otherAccount).approve(EasyStake.target, stakedAmount);
      
          // Stake tokens
          await EasyStake.connect(otherAccount).stake(stakedAmount, poolId);
      
          // Fast forward the blockchain time by a week
          await network.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 1 week
          await network.provider.send("evm_mine"); // Mine a block to finalize the time jump
      
          // Claim the reward after time has passed
          await expect(EasyStake.connect(otherAccount).claimReward(false, poolId))
            .to.emit(EasyStake, 'RewardClaimed')
            .withArgs(otherAccount.address, 1, false); // 1 weekpool gives 1 NFT reward
        });

        it("Should allow claiming reward after time has passed for 2 weeks pool", async function () {
            const { EasyStake, EasyToken, owner, otherAccount } = await loadFixture(deployEasyStake);
        
            const amountTransferred = 1000;
            const stakedAmount = 500;
            const poolId = 1;
        
            // Transfer tokens and approve EasyStake to use them
            await EasyToken.transfer(otherAccount.address, amountTransferred);
            await EasyToken.connect(otherAccount).approve(EasyStake.target, stakedAmount);
        
            // Stake tokens
            await EasyStake.connect(otherAccount).stake(stakedAmount, poolId);
        
            // Fast forward the blockchain time by a week
            await network.provider.send("evm_increaseTime", [14 * 24 * 60 * 60]); // Increase time by 2 weeks
            await network.provider.send("evm_mine"); // Mine a block to finalize the time jump
        
            // Claim the reward after time has passed
            await expect(EasyStake.connect(otherAccount).claimReward(false, poolId))
              .to.emit(EasyStake, 'RewardClaimed')
              .withArgs(otherAccount.address, 2, false); // 2 weekpool gives 2 NFT reward
          });

        it("Should allow claiming reward after time has passed for 3 weeks pool", async function () {
        const { EasyStake, EasyToken, owner, otherAccount } = await loadFixture(deployEasyStake);
    
        const amountTransferred = 1000;
        const stakedAmount = 500;
        const poolId = 2;
    
        // Transfer tokens and approve EasyStake to use them
        await EasyToken.transfer(otherAccount.address, amountTransferred);
        await EasyToken.connect(otherAccount).approve(EasyStake.target, stakedAmount);
    
        // Stake tokens
        await EasyStake.connect(otherAccount).stake(stakedAmount, poolId);
    
        // Fast forward the blockchain time by a week
        await network.provider.send("evm_increaseTime", [21 * 24 * 60 * 60]); // Increase time by 3 weeks
        await network.provider.send("evm_mine"); // Mine a block to finalize the time jump
    
        // Claim the reward after time has passed
        await expect(EasyStake.connect(otherAccount).claimReward(false, poolId))
            .to.emit(EasyStake, 'RewardClaimed')
            .withArgs(otherAccount.address, 3, false); // 3 weekpool gives 3 NFT reward
        });

        it("Should emit 'RewardClaimed' event correctly", async function () {
          const { EasyStake, owner, otherAccount, EasyToken } = await loadFixture(deployEasyStake);
    
          const amountTransferred = hre.ethers.parseUnits("1000", 18);
          const stakedAmount = hre.ethers.parseUnits("500", 18);
          const poolId = 0; // oneWeekPool
    
          // Transfer and approve
          await EasyToken.transfer(otherAccount.address, amountTransferred);
          await EasyToken.connect(otherAccount).approve(EasyStake.target, stakedAmount);
    
          // Stake tokens
          await EasyStake.connect(otherAccount).stake(stakedAmount, poolId);
    
          // Fast forward time by 1 week
          await network.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // 7 days
          await network.provider.send("evm_mine"); // Mine a new block to apply time change
    
          // Claim the reward and expect the event
          await expect(
            EasyStake.connect(otherAccount).claimReward(false, poolId)
          )
            .to.emit(EasyStake, 'RewardClaimed')
            .withArgs(otherAccount.address, 1, false); // poolId 0 gives 1 NFT reward
        });
      
        it("Should transfer tokens if _convertTokenToNft is false and time has ellapsed", async function () {
          const { EasyStake, owner, otherAccount, EasyToken } = await loadFixture(deployEasyStake);
      
          const amountTransferred = 1000;
          const stakedAmount = 500;
          const poolId = 0;
          const numberOfTokensPerReward = 25;
      
          // Transfer tokens and approve EasyStake to use them
          await EasyToken.transfer(otherAccount.address, amountTransferred);
          await EasyToken.connect(otherAccount).approve(EasyStake.target, stakedAmount);
      
          // Stake tokens
          await EasyStake.connect(otherAccount).stake(stakedAmount, poolId);
      
          // Fast forward the blockchain time by a week (to simulate time passage)
          await network.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
          await network.provider.send("evm_mine");

          
          const expectedTokenAmount = 1 * numberOfTokensPerReward;

          await EasyToken.approve(otherAccount, expectedTokenAmount);
      
          // Claim the reward as tokens (convertTokenToNft = false)
          await expect(EasyStake.connect(otherAccount).claimReward(false, poolId))
            .to.emit(EasyStake, 'RewardClaimed')
            .withArgs(otherAccount.address, 1, false);
      
            const userBalance= await EasyToken.balanceOf(otherAccount.address);

            // Check if tokens were transferred correctly
          expect(userBalance).to.equal(expectedTokenAmount + 500);
        });
      
    });

    describe("Test getEasyStakeBalance function", function () {
      it("Should return the correct balance of easyToken in the EasyStake contract", async function () {
          const { EasyStake, EasyToken, owner,  } = await loadFixture(deployEasyStake);
  
          const initialBalance = hre.ethers.parseUnits("1000", 18);
  
          // Transfer initial balance of EasyToken to EasyStake contract
          await EasyToken.transfer(EasyStake.target, initialBalance);
  
          // Call getEasyStakeBalance
          const balance = await EasyStake.getEasyStakeBalance();
  
          // Verify that the returned balance matches the initial balance
          expect(balance).to.equal(initialBalance);
      });
    });

});
  