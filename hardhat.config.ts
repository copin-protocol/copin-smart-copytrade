require("dotenv").config();
import "hardhat-gas-reporter";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
// import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 800,
      },
      viaIR: true,
      metadata: {
        bytecodeHash: "none",
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    goerli: {
      url: process.env.GOERLI_NODE_URL,
      accounts: [
        process.env.PRIVATE_KEY_1!,
        process.env.PRIVATE_KEY_2!,
        process.env.PRIVATE_KEY_3!,
      ],
    },
    polygon: {
      url: process.env.POLYGON_NODE_URL,
      accounts: [
        process.env.PRIVATE_KEY_1!,
        process.env.PRIVATE_KEY_2!,
        process.env.PRIVATE_KEY_3!,
      ],
    },
    gmxV1Mainnet: {
      url: process.env.ARB_NODE_URL,
      accounts: [
        process.env.PRIVATE_KEY_1!,
        process.env.PRIVATE_KEY_2!,
        process.env.PRIVATE_KEY_3!,
      ],
      ...{
        RELAYER_API_KEY: process.env.RELAYER_API_KEY!,
        RELAYER_API_SECRET: process.env.RELAYER_API_SECRET!,
        USD_ASSET: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
        AUTOMATE: "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
        EXECUTOR: "0xdD5918bA45A94A05965c7A8b63BE7CEA1460ABb3",
        FACTORY_ADDRESS: "0x6aCD1Ac7eeEa7783E805a1c4E31c85A4535d682B",
        EVENTS_ADDRESS: "0xeb452323b4bFb289867D21cAa524535F443a5904",
        CONFIGS_ADDRESS: "0x81Ed045eaB09B9164657A2EC76442f1337A38D0e",
        TASK_CREATOR_ADDRESS: "0x2Fe95465616F6252636fC101400147C0a1e64F6C",
        IMPLEMENTATION_ADDRESS: "0x6aFa95bCC134c91460521CF0c46340c936E0acA5",
        SMART_WALLET_ADDRESS: "0x1362011668ad0b665618b3cc0651F4aD7C36c147",
        ROUTER: "0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064",
        POSITION_ROUTER: "0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868",
        VAULT: "0x489ee077994B6658eAfA855C308275EAd8097C4A",
        WETH: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
      },
    },
    gnsV8Testnet: {
      url: process.env.ARB_SEPOLIA_NODE_URL,
      accounts: [
        process.env.PRIVATE_KEY_1!,
        process.env.PRIVATE_KEY_2!,
        process.env.PRIVATE_KEY_3!,
      ],
      ...{
        RELAYER_API_KEY: process.env.RELAYER_API_KEY!,
        RELAYER_API_SECRET: process.env.RELAYER_API_SECRET!,
        USD_ASSET: "0x4cC7EbEeD5EA3adf3978F19833d2E1f3e8980cD6",
        AUTOMATE: "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
        EXECUTOR: "0x949408171c4BE8C7017Ed4331B6c927Cbfe332cD",
        FACTORY_ADDRESS: "0x1e879694C79D68FCf48D90d09c2FeEb692AF2087",
        EVENTS_ADDRESS: "0xef68cEE62bc85650Ee96dbBaC7653B1BA103ADc6",
        CONFIGS_ADDRESS: "0x18F1EEF839277b373dEB02dAACEe31fB0a2f1165",
        TASK_CREATOR_ADDRESS: "0x32830388B4013e78F14429B3e9772A26A0A43BF8",
        IMPLEMENTATION_ADDRESS: "0xf4DcbD9F050939679A1aF432083DecF24eFe7aaF",
        SMART_WALLET_ADDRESS: "0xAA43BbA5f8ba9C90f43bB831130a7b8a8AA026Ef",
        GAINS_TRADING: "0xd659a15812064C79E189fd950A189b15c75d3186",
        PYTH: "0x4374e5a8b9C22271E9EB878A2AA31DE97DF15DAF",
        FEE_RECEIVER: "0xaa346103FD9a4Cd8936a96B0DF9bE603470E34cD",
      },
    },
    gnsV8Mainnet: {
      url: process.env.ARB_NODE_URL,
      accounts: [
        process.env.PRIVATE_KEY_1!,
        process.env.PRIVATE_KEY_2!,
        process.env.PRIVATE_KEY_3!,
      ],
      ...{
        RELAYER_API_KEY: process.env.RELAYER_API_KEY!,
        RELAYER_API_SECRET: process.env.RELAYER_API_SECRET!,
        USD_ASSET: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
        AUTOMATE: "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
        EXECUTOR: "0xbd3726fc0B8411869aE8268345cFfF48747F39da",
        FACTORY_ADDRESS: "0xAfAae4be2c07948eb83e003FfdB859b5e6cabC63",
        EVENTS_ADDRESS: "0x6c212E97390C124B37888bF4b491a1f9f63451eD",
        CONFIGS_ADDRESS: "0xB1f1c69A8385fC7F120d8bC03d8b1b143c663C20",
        TASK_CREATOR_ADDRESS: "0x397A9bb1273fed4a4Af9777Df9C256f1609709f0",
        IMPLEMENTATION_ADDRESS: "0xE8e97DB4445Ce6C1117C0A4d716Be1ca5DE8D5CD",
        SMART_WALLET_ADDRESS: "",
        GAINS_TRADING: "0xFF162c694eAA571f685030649814282eA457f169",
        PYTH: "0xff1a0f4744e8582DF1aE09D5611b887B6a12925C",
        FEE_RECEIVER: "0x5ADf41Cab6480d589C0dE7314EC95F6aE57ba7F6",
      },
    },
    snxV2Testnet: {
      url: process.env.OP_SEPOLIA_NODE_URL,
      accounts: [
        process.env.PRIVATE_KEY_1!,
        process.env.PRIVATE_KEY_2!,
        process.env.PRIVATE_KEY_3!,
      ],
      ...{
        RELAYER_API_KEY: process.env.RELAYER_API_KEY!,
        RELAYER_API_SECRET: process.env.RELAYER_API_SECRET!,
        USD_ASSET: "0xD7D674d80e79CF3A3b67D6a510AC1B0493dF47cF",
        AUTOMATE: "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
        EXECUTOR: "0xdDAf82aD2ceF6dDAB6170C46111398d7622eE829",
        FACTORY_ADDRESS: "0x329b3599e51B992879349C0388D29a5B06861B0B",
        EVENTS_ADDRESS: "0xD4c8b3710d399c1810e48365727FD28bD4ec0314",
        CONFIGS_ADDRESS: "0x21fb9EB59E29639A2c8DF595Ae20458231e1f7b5",
        TASK_CREATOR_ADDRESS: "0xa87959E220643ba53fA22004d2339C0B754a8F5E",
        IMPLEMENTATION_ADDRESS: "0xdfe5c95e004Eb2219AAf57B156d44f74E089bde9",
        SMART_WALLET_ADDRESS: "0xe3142E19bEaB8b69B3F1267D3C9A91E14C8ead0b",
        ETH_MARKET_KEY:
          "0x7345544850455250000000000000000000000000000000000000000000000000",
        SNX_EXCHANGE_RATE: "0xBDA9863eFC244692816814E686Bd3A94aEc604Ad",
        SNX_MARKET_MANAGER: "0x00D79DBB8e9fC344C015ADD2D4135E5181b61e66",
        SNX_SYSTEM_STATUS: "0x247814db4369f8E952F60A6409C16A928672dcc6",
      },
      // gasPrice: 60,
    },
    snxV2Mainnet: {
      url: process.env.OP_NODE_URL,
      accounts: [
        process.env.PRIVATE_KEY_1!,
        process.env.PRIVATE_KEY_2!,
        process.env.PRIVATE_KEY_3!,
      ],
      ...{
        RELAYER_API_KEY: process.env.RELAYER_API_KEY!,
        RELAYER_API_SECRET: process.env.RELAYER_API_SECRET!,
        USD_ASSET: "0x8c6f28f2f1a3c87f0f938b96d27520d9751ec8d9",
        AUTOMATE: "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
        EXECUTOR: "0x76Ea7951214A0a3b8D132fb7C80c174dbeD62bcf",
        FACTORY_ADDRESS: "0xB27A14Fa98608A95d81C22023F09648f2Cb714C2",
        EVENTS_ADDRESS: "0x88680E90D1Bcb8Bf1AD5cd0F65f99851803F9A04",
        CONFIGS_ADDRESS: "0x1d66C1D46135DEc47EBfA044Ea1dB230adA68284",
        TASK_CREATOR_ADDRESS: "0x6c0D18C82E5AACAc466889bF433f766cd54281e1",
        IMPLEMENTATION_ADDRESS: "0x81Ed045eaB09B9164657A2EC76442f1337A38D0e",
        SMART_WALLET_ADDRESS: "",
        ETH_MARKET_KEY:
          "0x7345544850455250000000000000000000000000000000000000000000000000",

        SNX_EXCHANGE_RATE: "0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04",
        SNX_MARKET_MANAGER: "0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463",
        SNX_SYSTEM_STATUS: "0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD",
      },
    },
    snxV3Testnet: {
      url: process.env.BASE_SEPOLIA_NODE_URL,
      accounts: [
        process.env.PRIVATE_KEY_1!,
        process.env.PRIVATE_KEY_2!,
        process.env.PRIVATE_KEY_3!,
      ],
      ...{
        RELAYER_API_KEY: process.env.RELAYER_API_KEY!,
        RELAYER_API_SECRET: process.env.RELAYER_API_SECRET!,
        USD_ASSET: "0xc43708f8987Df3f3681801e5e640667D86Ce3C30",
        AUTOMATE: "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
        EXECUTOR: "0x57EBeCaCcd47322EbD31D68f8DbC1d29d233b0f0",
        FACTORY_ADDRESS: "0x03b8452Dd1E2625fD27c006693189f56F73DEa6b",
        EVENTS_ADDRESS: "0xF7550f0C091477e24E31b39bCE2333CFFbaBA663",
        CONFIGS_ADDRESS: "0xc711ad2753232bb2e1b48a63B944CE12a78fbBaf",
        TASK_CREATOR_ADDRESS: "0x329b3599e51B992879349C0388D29a5B06861B0B",
        IMPLEMENTATION_ADDRESS: "0xD4c8b3710d399c1810e48365727FD28bD4ec0314",
        SMART_WALLET_ADDRESS: "0xCf125F42Ff3bDfe8568f107e9298d60E30DEBaCF",
        SNX_PERPS_MARKET: "0xf53Ca60F031FAf0E347D44FbaA4870da68250c8d",
        SNX_SPOT_MARKET: "0xaD2fE7cd224c58871f541DAE01202F93928FEF72",
        SNX_SUSDC: "0x8069c44244e72443722cfb22DcE5492cba239d39",
        SNX_SUSD: "0x682f0d17feDC62b2a0B91f8992243Bf44cAfeaaE",
      },
    },
    snxV3Mainnet: {
      url: process.env.BASE_NODE_URL,
      accounts: [
        process.env.PRIVATE_KEY_1!,
        process.env.PRIVATE_KEY_2!,
        process.env.PRIVATE_KEY_3!,
      ],
      ...{
        RELAYER_API_KEY: process.env.RELAYER_API_KEY!,
        RELAYER_API_SECRET: process.env.RELAYER_API_SECRET!,
        USD_ASSET: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
        AUTOMATE: "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
        EXECUTOR: "0xC5417a77f8b0649c47d00363370D9D4A25e7d1Ef",
        FACTORY_ADDRESS: "0xfC9339f4CE0Cb840C64f9F7cBbcdf16C4eD008a0",
        EVENTS_ADDRESS: "0x2Fe95465616F6252636fC101400147C0a1e64F6C",
        CONFIGS_ADDRESS: "0x8DA098F5eA19050FC058c70bcE078eea9fC4e43D",
        TASK_CREATOR_ADDRESS: "0x346923f800A8DB39d89cD21e367d46af916F73B5",
        IMPLEMENTATION_ADDRESS: "0x31D191100D3bBE0815a1cA82b52B49454e4A514d",
        SMART_WALLET_ADDRESS: "",
        SNX_PERPS_MARKET: "0x0A2AF931eFFd34b81ebcc57E3d3c9B1E1dE1C9Ce",
        SNX_SPOT_MARKET: "0x18141523403e2595D31b22604AcB8Fc06a4CaA61",
        SNX_SUSDC: "0xc74ea762cf06c9151ce074e6a569a5945b6302e7",
        SNX_SUSD: "0x09d51516F38980035153a554c26Df3C6f51a23C3",
      },
    },
  },
  gasReporter: {
    currency: "USD",
    token: "ETH",
    gasPrice: 22,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY!,
      optimisticEthereum: process.env.OPSCAN_API_KEY!,
      base: process.env.BASESCAN_API_KEY!,
      arbitrumOne: process.env.ARBISCAN_API_KEY!,
    },
    customChains: [
      // {
      //   network: "base",
      //   chainId: 84531,
      //   urls: {
      //     apiURL: "https://api-goerli.basescan.org/api",
      //     browserURL: "https://goerli.basescan.org",
      //   },
      // },
      {
        network: "arbitrumOne",
        chainId: 421614,
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://sepolia.arbiscan.io",
        },
      },
      {
        network: "base",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org",
        },
      },
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org",
        },
      },
      {
        network: "optimisticEthereum",
        chainId: 11155420,
        urls: {
          apiURL: "https://api-sepolia-optimism.etherscan.io/api",
          browserURL: "https://sepolia-optimism.etherscan.io",
        },
      },
    ],
  },
};

export default config;
