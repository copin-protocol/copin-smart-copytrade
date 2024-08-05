import { ethers, network } from "hardhat";
import { abi as configAbi } from "../artifacts/contracts/Configs.sol/Configs.json";
import { CONFIG } from "../utils/constants";

async function main() {
  const [wallet1, wallet2, wallet3] = await ethers.getSigners();
  const config = new ethers.Contract(
    CONFIG.CONFIGS_ADDRESS,
    configAbi,
    wallet1 as any
  );
  const executor = "0xa6fb623a4a1e811C03c3e1bCF6a0C565aC3fA068";
  console.log("executor", executor);
  const tx = await config.addExecutor(executor);
  console.log(tx);
}

main();
