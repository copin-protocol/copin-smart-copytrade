import { ethers, network, run } from "hardhat";
import { GNSv8NetworkConfig } from "../../utils/types/config";
import { CONFIG } from "../../utils/constants";

async function main() {
  const usdAsset = (network.config as GNSv8NetworkConfig).USD_ASSET;
  const gainsTrading = (network.config as GNSv8NetworkConfig).GAINS_TRADING;
  const pyth = (network.config as GNSv8NetworkConfig).PYTH;
  const feeReceiver = (network.config as GNSv8NetworkConfig).FEE_RECEIVER;
  const automate = (network.config as GNSv8NetworkConfig).AUTOMATE;
  const [wallet] = await ethers.getSigners();

  const factory = { address: CONFIG.FACTORY_ADDRESS };
  const events = { address: CONFIG.EVENTS_ADDRESS };
  const configs = { address: CONFIG.CONFIGS_ADDRESS };
  const taskCreator = { address: CONFIG.TASK_CREATOR_ADDRESS };
  const implementation = {
    address: CONFIG.IMPLEMENTATION_ADDRESS,
  };

  // await run("verify:verify", {
  //   address: factory.address,
  //   constructorArguments: [wallet.address],
  // });
  // await run("verify:verify", {
  //   address: events.address,
  //   constructorArguments: [factory.address],
  // });
  // await run("verify:verify", {
  //   address: configs.address,
  //   constructorArguments: [feeReceiver],
  // });
  // await run("verify:verify", {
  //   address: taskCreator.address,
  //   constructorArguments: [factory.address, automate],
  // });
  await run("verify:verify", {
    address: implementation.address,
    constructorArguments: [
      {
        factory: factory.address,
        events: events.address,
        configs: configs.address,
        usdAsset,
        automate,
        taskCreator: taskCreator.address,
        gainsTrading,
        pyth,
      },
    ],
  });
}

main();
