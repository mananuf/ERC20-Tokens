import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const EasyTokenModule = buildModule("EasyTokenModule", (m) => {
   
  const easyToken = m.contract("EasyToken");

  return { easyToken };
});

export default EasyTokenModule;
