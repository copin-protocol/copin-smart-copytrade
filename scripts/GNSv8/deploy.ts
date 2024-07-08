import { ethers, network, run } from "hardhat";
import { abi as factoryAbi } from "../../artifacts/contracts/Factory.sol/Factory.json";
import { GNSv8NetworkConfig } from "../../utils/types/config";
import { CONFIG } from "../../utils/constants";

async function main() {
  const usdAsset = (network.config as GNSv8NetworkConfig).USD_ASSET;
  const gainsTrading = (network.config as GNSv8NetworkConfig).GAINS_TRADING;
  const pyth = (network.config as GNSv8NetworkConfig).PYTH;
  const automate = (network.config as GNSv8NetworkConfig).AUTOMATE;
  const feeReceiver = (network.config as GNSv8NetworkConfig).FEE_RECEIVER;

  const [wallet] = await ethers.getSigners();

  // const Factory = await ethers.getContractFactory("Factory");
  // const factory = await Factory.deploy(wallet.address);
  // await factory.deployed();
  // console.log("Factory deployed to:", factory.address);
  const factory = new ethers.Contract(CONFIG.FACTORY_ADDRESS, factoryAbi);

  // const Events = await ethers.getContractFactory("Events");
  // const events = await Events.deploy(factory.address);
  // await events.deployed();
  // console.log("Events deployed to:", events.address);
  const events = { address: CONFIG.EVENTS_ADDRESS };

  const Configs = await ethers.getContractFactory("Configs");
  const configs = await Configs.deploy(feeReceiver);
  await configs.deployed();
  console.log("Configs deployed to:", configs.address);
  // const configs = { address: CONFIG.CONFIGS_ADDRESS };

  // const TaskCreator = await ethers.getContractFactory("TaskCreator");
  // const taskCreator = await TaskCreator.deploy(factory.address, automate);
  // await taskCreator.deployed();
  // console.log("TaskCreator deployed to:", taskCreator.address);
  const taskCreator = { address: CONFIG.TASK_CREATOR_ADDRESS };

  // console.log({
  //   factory: factory.address,
  //   events: events.address,
  //   configs: configs.address,
  //   usdAsset,
  //   automate,
  //   taskCreator: taskCreator.address,
  //   router,
  //   positionRouter,
  //   vault,
  //   weth,
  // });
  // return;

  const CopyWallet = await ethers.getContractFactory("CopyWalletGNSv8");
  const implementation = await CopyWallet.deploy({
    factory: factory.address,
    events: events.address,
    configs: configs.address,
    usdAsset,
    automate,
    taskCreator: taskCreator.address,
    gainsTrading,
    pyth,
  });
  console.log("CopyWallet Implementation deployed to:", implementation.address);
  // const implementation = {
  //   address: CONFIG.IMPLEMENTATION_ADDRESS,
  // };

  await new Promise((resolve) =>
    setTimeout(() => {
      resolve(true);
    }, 3000)
  );

  const tx = await factory
    .connect(wallet as any)
    .upgradeCopyWalletImplementation(implementation.address);

  console.log("update", tx);
}

main();
