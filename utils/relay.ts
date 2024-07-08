import { Defender } from "@openzeppelin/defender-sdk";
import { CONFIG } from "./constants";

export const getRelaySigner = () => {
  console.log("CONFIG.RELAYER_API_KEY", CONFIG.RELAYER_API_KEY);
  const credentials = {
    relayerApiKey: CONFIG.RELAYER_API_KEY,
    relayerApiSecret: CONFIG.RELAYER_API_SECRET,
  };
  const client = new Defender(credentials);
  const provider = client.relaySigner.getProvider();
  const signer = client.relaySigner.getSigner(provider, {
    speed: "fastest",
    validForSeconds: 120,
  });
  return signer;
};
