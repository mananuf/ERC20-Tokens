import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import * as dotenv from "dotenv";
dotenv.config();


const EasyStakeModule = buildModule("EasyStakeModule", (m) => {
  const EASY_TOKEN_ADDRESS = "0xA48331133465F9bC5c05dBEF2B0c4026ca52779b";
  const NFT_TOKEN_ADDRESS = "0x3e940762B2d3EC049FF075064bED358720a9260B";
  
  const easyStake = m.contract("EasyStake", [EASY_TOKEN_ADDRESS, NFT_TOKEN_ADDRESS]);

  return { easyStake };
});

export default EasyStakeModule;
