import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import hre from "hardhat";
  import ethers from "hardhat";
  
  describe("ERC20", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.

    //create state variables
    const _name = "ERC20";
    const _symbol = "ERC";
    const _decimals = 18;
    const addressZero = "0x0000000000000000000000000000000000000000";

    async function deployERC20() {
        const [deployer, otherAccount, thirdAccount] = await hre.ethers.getSigners();
        const erc20 = await hre.ethers.getContractFactory("CustomERC20");
        const ERC20Contract = await erc20.deploy(_name, _symbol, _decimals);

        return { ERC20Contract, deployer, otherAccount, thirdAccount }
    }

    // Test Mint function
    describe("Test Internal mint function to create tokens", function () {
        it("Should revert if mintable address is address(0)", async function () {
          const { ERC20Contract, deployer } = await loadFixture(deployERC20);
    
          await expect(ERC20Contract.testMint(addressZero, 1000000)).to.be.revertedWithCustomError(ERC20Contract, "InvalidReceiver");
        });

        it("Should pass if mintable address is not address(0)", async function () {
            const { ERC20Contract, deployer } = await loadFixture(deployERC20);

            const amountToMint = hre.ethers.parseUnits("1000", 18);

            expect(await ERC20Contract.balanceOf(deployer)).to.be.equal(hre.ethers.parseUnits("0", 18));

            await ERC20Contract.testMint(deployer, amountToMint);

            expect(await ERC20Contract.balanceOf(deployer)).to.be.equal(amountToMint);
          });

          it("Should emit right parameters if mint was executed succesfully", async function () {
            const { ERC20Contract, deployer } = await loadFixture(deployERC20);

            const amountToMint = hre.ethers.parseUnits("1000", 18);
            expect(await ERC20Contract.testMint(deployer, amountToMint)).to.emit(ERC20Contract, 'Transfer').withArgs(addressZero, deployer, amountToMint);
          });
      });

      // Test Burn function
    describe("Test Internal burn function", function () {
        it("Should revert if burnable address is address(0)", async function () {
          const { ERC20Contract, deployer } = await loadFixture(deployERC20);
    
          await expect(ERC20Contract.testBurn(addressZero, 1000000)).to.be.revertedWithCustomError(ERC20Contract, "InvalidSender");
        });

        it("Should pass if burnable address is not address(0) and has sufficient balance", async function () {
            const { ERC20Contract, deployer } = await loadFixture(deployERC20);

            const amountToMint = hre.ethers.parseUnits("1000", 18);
            const amountToBurn = hre.ethers.parseUnits("400", 18);

            // mint so the balance will have sufficient balance
            await ERC20Contract.testMint(deployer, amountToMint);

            // check that balance has increased
            expect(await ERC20Contract.balanceOf(deployer)).to.be.equal(amountToMint);

            await ERC20Contract.testBurn(deployer, amountToBurn);

            // check that balance have have been deducted
            expect(await ERC20Contract.balanceOf(deployer)).to.be.equal(hre.ethers.parseUnits("600", 18));
          });

        it("Should fail if burnable amount is more than available balance", async function () {
            const { ERC20Contract, deployer } = await loadFixture(deployERC20);

            const amountToBurn = hre.ethers.parseUnits("1400", 18);

            await expect(ERC20Contract.testBurn(deployer, amountToBurn)).to.be.revertedWithCustomError(ERC20Contract, "InsufficientBalance");
        });

        it("Should emit right parameters if burn was executed succesfully", async function () {
        const { ERC20Contract, deployer } = await loadFixture(deployERC20);

        const amountToMint = hre.ethers.parseUnits("1000", 18);
        const amountToBurn = hre.ethers.parseUnits("400", 18);

        // mint so the balance will have sufficient balance
        await ERC20Contract.testMint(deployer, amountToMint);
        await expect(ERC20Contract.testBurn(deployer, amountToBurn)).to.emit(ERC20Contract, "Transfer").withArgs(deployer.address, addressZero, amountToBurn);
        });
      });

      // Test spendAlllowance function
    describe("Test Internal _spendAllowance function", function () {
        it("Should revert if user doesnt have allowance", async function () {
          const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);

          const amount = hre.ethers.parseUnits("1000", 18);
    
          await expect(ERC20Contract.testSpendAllowance(deployer, otherAccount, amount )).to.be.revertedWithCustomError(ERC20Contract, "InsufficientAllowance");
        });

        it("Should revert if user doesnt have sufficient balance", async function () {
            const { ERC20Contract, deployer, otherAccount, thirdAccount } = await loadFixture(deployERC20);

            const amountToMint = hre.ethers.parseUnits("1000", 18);

            // mint so the balance will have sufficient balance
            await ERC20Contract.testMint(deployer, amountToMint);
  
            const amount = hre.ethers.parseUnits("100", 18);

            await ERC20Contract.transfer(otherAccount.address, amount);

            await ERC20Contract.connect(otherAccount).approve(thirdAccount, amount);
      
            await expect(ERC20Contract.testSpendAllowance(otherAccount, thirdAccount, hre.ethers.parseUnits("110", 18) )).to.be.revertedWithCustomError(ERC20Contract, "InsufficientAllowance");
          });

        it("Should pass if user has sufficient balance and allowance", async function () {
            const { ERC20Contract, deployer, otherAccount, thirdAccount } = await loadFixture(deployERC20);

            const amountToMint = hre.ethers.parseUnits("1000", 18);

            // mint so the balance will have sufficient balance
            await ERC20Contract.testMint(deployer, amountToMint);
  
            const amount = hre.ethers.parseUnits("100", 18);

            await ERC20Contract.transfer(otherAccount.address, amount);

            await ERC20Contract.connect(otherAccount).approve(thirdAccount, amount);
      
            await ERC20Contract.testSpendAllowance(otherAccount, thirdAccount, hre.ethers.parseUnits("100", 18) );
          });
      });

      // Test _approve function
    describe("Test Internal _approve function", function () {
        it("Should revert approval if owner to give approval address is address(0)", async function () {
            const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);
      
            await expect(ERC20Contract.test_approve(addressZero, otherAccount, 1000000)).to.be.revertedWithCustomError(ERC20Contract, "InvalidApprover");
          });

          it("Should revert approval if spender address is address(0)", async function () {
            const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);
      
            await expect(ERC20Contract.test_approve(otherAccount, addressZero, 1000000)).to.be.revertedWithCustomError(ERC20Contract, "InvalidSpender");
          });
          
        it("Should revert approval if user doesnt have balance", async function () {
          const { ERC20Contract, deployer, otherAccount, thirdAccount } = await loadFixture(deployERC20);

          const amount = hre.ethers.parseUnits("1000", 18);
    
          expect(await ERC20Contract.test_approve(otherAccount, thirdAccount, amount)).to.be.revertedWithCustomError(ERC20Contract, "InsufficientAllowance");
        });

        it("Should approve spender if user has sufficient balance and allowance", async function () {
            const { ERC20Contract, deployer, otherAccount, thirdAccount } = await loadFixture(deployERC20);

            const amountToMint = hre.ethers.parseUnits("1000", 18);

            // mint so the balance will have sufficient balance
            await ERC20Contract.testMint(deployer, amountToMint);
  
            const amount = hre.ethers.parseUnits("100", 18);

            await ERC20Contract.transfer(otherAccount.address, amount);

            await ERC20Contract.connect(otherAccount).test_approve(otherAccount, thirdAccount, amount);
          });

          it("Should emit correct parameters when spender is approved", async function () {
            const { ERC20Contract, deployer, otherAccount, thirdAccount } = await loadFixture(deployERC20);

            const amountToMint = hre.ethers.parseUnits("1000", 18);

            // mint so the balance will have sufficient balance
            await ERC20Contract.testMint(deployer, amountToMint);
  
            const amount = hre.ethers.parseUnits("100", 18);

            await ERC20Contract.transfer(otherAccount.address, amount);

            await expect(ERC20Contract.connect(otherAccount).test_approve(otherAccount, thirdAccount, amount)).to.emit(ERC20Contract, "Approval").withArgs(otherAccount, thirdAccount, amount);
          });
      });

      // Test _transfer function
    describe("Test Internal _transfer function", function () {
        it("Should revert transfer if address to transfer from is address(0)", async function () {
            const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);
      
            await expect(ERC20Contract.test_transfer(addressZero, otherAccount, 1000000)).to.be.revertedWithCustomError(ERC20Contract, "InvalidSender");
          });

          it("Should revert transfer if receiver address is address(0)", async function () {
            const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);
      
            await expect(ERC20Contract.test_transfer(otherAccount, addressZero, 1000000)).to.be.revertedWithCustomError(ERC20Contract, "InvalidReceiver");
          });
          
        it("Should revert transfer if sender doesnt have sufficient balance", async function () {
          const { ERC20Contract, deployer, otherAccount, thirdAccount } = await loadFixture(deployERC20);

          const amount = hre.ethers.parseUnits("1000", 18);
    
          await expect(ERC20Contract.test_transfer(otherAccount, thirdAccount, amount)).to.be.revertedWithCustomError(ERC20Contract, "InsufficientBalance");
        });

        it("Should transfer if sender has sufficient balance", async function () {
            const { ERC20Contract, deployer, otherAccount, thirdAccount } = await loadFixture(deployERC20);

            const amountToMint = hre.ethers.parseUnits("1000", 18);

            // mint so the balance will have sufficient balance
            await ERC20Contract.testMint(deployer, amountToMint);
  
            const amount = hre.ethers.parseUnits("100", 18);

            await ERC20Contract.transfer(otherAccount.address, amount);

            await ERC20Contract.connect(otherAccount).test_transfer(otherAccount, thirdAccount, hre.ethers.parseUnits("10", 18));
          });

          it("Should emit correct parameters when spender is approved", async function () {
            const { ERC20Contract, deployer, otherAccount, thirdAccount } = await loadFixture(deployERC20);

            const amountToMint = hre.ethers.parseUnits("1000", 18);

            // mint so the balance will have sufficient balance
            await ERC20Contract.testMint(deployer, amountToMint);
  
            const amount = hre.ethers.parseUnits("100", 18);

            await ERC20Contract.transfer(otherAccount.address, amount);

            await expect(ERC20Contract.connect(otherAccount)
                        .test_transfer(otherAccount, thirdAccount, hre.ethers.parseUnits("10", 18)))
                        .to.emit(ERC20Contract, "Transfer")
                        .withArgs(otherAccount, thirdAccount, hre.ethers.parseUnits("10", 18));
          });
      });

      describe("test for deploying the token", function () {
        it("should test for erc20 deployment", async() => {
             const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);

             expect(await ERC20Contract.name()).to.eq("ERC20");
             expect(await ERC20Contract.name()).to.not.eq("gibberish");
        })
    })

    describe("Test ERC20 balanceOf function", function () {
        it("should test for erc20 deployment", async() => {
             const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);

             expect(await ERC20Contract.balanceOf(deployer)).to.eq(0);
             expect(await ERC20Contract.balanceOf(deployer)).to.not.eq(7);
        })
    })

    describe("Test ERC20 balanceOf when token is minted function", function () {
        it("should test for balanceOf addresses at different points", async() => {
            const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);

            // test allowance functionality before minting
            expect(await ERC20Contract.allowance(deployer, otherAccount)).to.eq(0);

            const amountToMint = hre.ethers.parseUnits("1000", 18);

            
            const mintingOp = await ERC20Contract.testMint(deployer, amountToMint);
            
            expect(await ERC20Contract.balanceOf(deployer)).to.eq(amountToMint);
        })
    })

    describe("Test ERC20 allowance function", function () {
        it("should test for erc20 allowance", async() => {
            const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);

            // test allowance functionality before minting
            expect(await ERC20Contract.allowance(deployer, otherAccount)).to.eq(0);

            const amountToMint = hre.ethers.parseUnits("1000", 18);
            const mintingOp = await ERC20Contract.testMint(deployer, amountToMint);

            const amountToApprove = hre.ethers.parseUnits("10", 18);

            await ERC20Contract.approve(otherAccount, amountToApprove);
            
            expect(await ERC20Contract.balanceOf(deployer)).to.eq(amountToMint);
        })

        it("should test for erc20 after approval", async () => {
            const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);


            const amountToMint = hre.ethers.parseUnits("1000", 18);
            const mintingOp = await ERC20Contract.testMint(deployer, amountToMint);

            const amountToApprove = hre.ethers.parseUnits("10", 18);

            await ERC20Contract.connect(deployer).approve(otherAccount, amountToApprove);
            
            expect(await ERC20Contract.allowance(deployer, otherAccount)).to.eq(amountToApprove);
        })
    })

    describe("Test ERC20 transfer function", function () {
        it("should test for erc20 transfer", async() => {
             const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);

             const amountToMint = hre.ethers.parseUnits("1000", 18);
             const mintingOp = await ERC20Contract.testMint(deployer, amountToMint);

             const amountToTransfer = hre.ethers.parseUnits("10", 18);

             await ERC20Contract.connect(deployer).transfer(otherAccount, amountToTransfer);

             expect(await ERC20Contract.balanceOf(otherAccount)).to.eq(amountToTransfer);
        })
    })

    describe("Test ERC20 transferFrom function", function () {
        it("should transferFrom from sender to spender account is suucessful", async() => {
             const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);

             const amountToMint = hre.ethers.parseUnits("1000", 18);
             const mintingOp = await ERC20Contract.testMint(deployer, amountToMint);

             const amountToApprove = hre.ethers.parseUnits("10", 18);

             await ERC20Contract.connect(deployer).approve(otherAccount, amountToApprove);

             const transferFromTx = await ERC20Contract.connect(otherAccount).transferFrom(deployer, otherAccount, amountToApprove);

            expect(await ERC20Contract.balanceOf(otherAccount)).to.eq(amountToApprove);
        })
    })

    describe("Test ERC20 symbol function", function () {
        it("should test for erc20 symbol on deployment", async() => {
             const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);

             expect(await ERC20Contract.symbol()).to.eq("ERC");
             expect(await ERC20Contract.symbol()).to.not.eq("gibberish");
             expect(await ERC20Contract.symbol()).to.not.eq(1233);
        })
    })

    describe("Test ERC20 totalSuply function", function () {
        it("should test for erc20 totalSuply on deployment", async() => {
             const { ERC20Contract, deployer, otherAccount } = await loadFixture(deployERC20);
             const ammountToEarned = hre.ethers.parseUnits("10000", 18)
             const mintingOp = await ERC20Contract.testMint(deployer, ammountToEarned);
             await ERC20Contract.connect(deployer).balanceOf(deployer);
             expect(await ERC20Contract.totalSupply()).to.eq(ammountToEarned);
            
        })
    })

  });