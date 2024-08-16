// 0x81f6db11736589eab14b59c5251c27482e6c7c12
import { ethers, network } from "hardhat";
import { abi as accountAbi } from "../../artifacts/contracts/CopyWalletGNSv8.sol/CopyWalletGNSv8.json";
import { CONFIG, Command } from "../../utils/constants";
import { getRelaySigner } from "../../utils/relay";

// const { formatUnits } = require("ethers/lib/utils");

const abi = ethers.utils.defaultAbiCoder;

async function main() {
  const signer = getRelaySigner();
  const account = new ethers.Contract(
    CONFIG.SMART_WALLET_ADDRESS,
    accountAbi,
    signer as any
  );
  console.log("account", account.address);

  const tx = await account.execute(
    [Command.PERP_CLOSE_ORDER],
    [abi.encode(["address", "uint256"], [CONFIG.SMART_WALLET_ADDRESS, 2])]
  );
  console.log("tx", tx);
}

main();
