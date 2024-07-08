// 0x81f6db11736589eab14b59c5251c27482e6c7c12
import { ethers, network } from "hardhat";
import { abi as accountAbi } from "../../artifacts/contracts/CopyWalletSNXv2.sol/CopyWalletSNXv2.json";
import { CONFIG, Command } from "../../utils/constants";
import { getRelaySigner } from "../../utils/relay";

// const { formatUnits } = require("ethers/lib/utils");

const abi = ethers.utils.defaultAbiCoder;

async function main() {
  const signer = getRelaySigner();
  // CONFIG.SMART_WALLET_ADDRESS = "0xfe4A52967092806d12A8AD6e30119930e8D10098";
  const account = new ethers.Contract(
    CONFIG.SMART_WALLET_ADDRESS,
    accountAbi,
    signer as any
  );
  console.log("account", account.address);

  const pairIndex = 1;
  const isLong = true;
  const collateral = ethers.utils.parseUnits("20", 6);

  // return;

  const tx = await account.execute(
    [Command.PERP_MODIFY_COLLATERAL],
    [abi.encode(["uint256", "uint256", "bool"], [29, collateral, false])]
  );
  console.log("tx", tx);
}

main();
