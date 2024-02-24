import { NetworkConfig } from "hardhat/types";

export type CopinConfig = {
  url: string;
  USD_ASSET: string;
  AUTOMATE: string;
  EXECUTOR: string;
  FACTORY_ADDRESS: string;
  EVENTS_ADDRESS: string;
  CONFIGS_ADDRESS: string;
  TASK_CREATOR_ADDRESS: string;
  IMPLEMENTATION_ADDRESS: string;
  SMART_WALLET_ADDRESS: string;
  RELAYER_API_KEY: string;
  RELAYER_API_SECRET: string;
};

export type SNXv3NetworkConfig = NetworkConfig &
  CopinConfig & {
    SNX_PERPS_MARKET: string;
    SNX_SPOT_MARKET: string;
    SNX_SUSDC: string;
    SNX_SUSD: string;
  };
export type SNXv2NetworkConfig = NetworkConfig &
  CopinConfig & {
    ETH_MARKET_KEY: string;
    SNX_EXCHANGE_RATE: string;
    SNX_MARKET_MANAGER: string;
    SNX_SYSTEM_STATUS: string;
  };
