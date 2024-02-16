import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";

const config: HardhatUserConfig = {
  solidity: {
    version:  "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000,
      }
    }
  }

};

export default config;
