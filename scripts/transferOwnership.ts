import { ethers, network } from "hardhat";
import { abi as factoryAbi } from "../artifacts/contracts/Factory.sol/Factory.json";
import { abi as configAbi } from "../artifacts/contracts/Configs.sol/Configs.json";
import { CONFIG } from "../utils/constants";

async function main() {
  const [wallet1] = await ethers.getSigners();
  // const factory = new ethers.Contract(
  //   CONFIG.FACTORY_ADDRESS,
  //   factoryAbi,
  //   wallet1 as any
  // );

  // const tx = await factory.transferOwnership(
  //   "0x5ADf41Cab6480d589C0dE7314EC95F6aE57ba7F6"
  // );
  // console.log(tx);

  const config = new ethers.Contract(
    CONFIG.CONFIGS_ADDRESS,
    configAbi,
    wallet1 as any
  );

  const tx = await config.transferOwnership(
    "0x5ADf41Cab6480d589C0dE7314EC95F6aE57ba7F6"
  );
  console.log(tx);
}

main();
