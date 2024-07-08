import { network } from "hardhat";
import {
  GMXv1NetworkConfig,
  SNXv2NetworkConfig,
  SNXv3NetworkConfig,
  GNSv8NetworkConfig,
} from "./types/config";

export const CONFIG = network.config as
  | SNXv3NetworkConfig
  | SNXv2NetworkConfig
  | GMXv1NetworkConfig
  | GNSv8NetworkConfig;

export const PROTOCOL_FEE = 4000;

export enum Command {
  OWNER_MODIFY_FUND = 0,
  OWNER_WITHDRAW_ETH = 1,
  OWNER_WITHDRAW_TOKEN = 2,
  PERP_CREATE_ACCOUNT = 3,
  PERP_MODIFY_COLLATERAL = 4,
  PERP_PLACE_ORDER = 5,
  PERP_CLOSE_ORDER = 6,
  PERP_CANCEL_ORDER = 7,
  PERP_WITHDRAW_ALL_MARGIN = 8,
  GELATO_CREATE_TASK = 9,
  GELATO_UPDATE_TASK = 10,
  GELETO_CANCEL_TASK = 11,
  PERP_UPDATE_SLTP = 12,
}

export const SNX_V3_MARKET_IDS = {
  ETH: 100,
  BTC: 200,
};
