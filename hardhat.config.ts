import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    // for testnet
    "sepolia": {
      url: process.env.SEPOLIA_RPC_URL!,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY!],
    },
  },
   
};

export default config;
