// 0x81f6db11736589eab14b59c5251c27482e6c7c12
import { ethers, network } from "hardhat";
import { abi as copyWalletAbi } from "../../artifacts/contracts/CopyWalletGNSv8.sol/CopyWalletGNSv8.json";
import gainsV8Abi from "../../utils/abis/gainsV8Abi";
import { CONFIG } from "../../utils/constants";
import { CopinConfig, GNSv8NetworkConfig } from "../../utils/types/config";
import { Call, multicall } from "../../utils/multicall";
import { getRelaySigner } from "../../utils/relay";
// const { formatUnits } = require("ethers/lib/utils");

export const MARGIN = ethers.utils.parseUnits("600", 6);

async function main() {
  const signer = getRelaySigner();

  const address = "ADDRESS_HERE";
  const batch = 0;

  const copyWallet = new ethers.Contract(address, copyWalletAbi, signer as any);

  const calls: Call[] = [...Array(100).keys()].map((i) => ({
    address,
    name: "hasCloseCharged",
    params: [batch + i],
  }));

  const data = await multicall(copyWalletAbi, calls, signer as any);
  const unchargedData = data
    .map((e: any, i: number) => ({ charged: e[0], index: batch + i }))
    .filter((e: any) => e.charged === false);
  console.log(unchargedData);

  const txs = await Promise.all(
    unchargedData.map((e: any) => copyWallet.chargeCloseFee(e.index))
  );
  console.log(
    "txs",
    txs.map((e: any) => e.hash)
  );
}
main();
