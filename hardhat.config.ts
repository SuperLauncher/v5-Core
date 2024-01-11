import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import "hardhat-watcher";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  defaultNetwork: "localhost",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    hardhat: {
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
    },
    "bscTN": {
      url: "https://data-seed-prebsc-1-s2.binance.org:8545",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    "bscMN": {
      url: "https://bsc-dataseed2.binance.org",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    "arb-goerli": {
      url:
        process.env.ARB_Goerli_URL || "https://goerli-rollup.arbitrum.io/rpc",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    "arb-mn": {
      url: process.env.ARB_URL || `https://rpc.ankr.com/arbitrum`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli" // URL of the Ethereum Web3 RPC (optional)
    },
    ethmMainnet: {
      url: "https://rpc.ankr.com/eth_goerli" // URL of the Ethereum Web3 RPC (optional)
    },
    // zkSyncTestnet: {
    //   url: "https://zksync2-testnet.zksync.dev",
    //   ethNetwork: "goerli", // Can also be the RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
    //   zksync: true,
    //   verifyURL: 'https://zksync2-testnet-explorer.zksync.dev/contract_verification'
    // },
    // zkSyncMainnet: {
    //   url: "https://mainnet.era.zksync.io",
    //   ethNetwork: "ethmMainnet", // Can also be the RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
    //   zksync: true,
    //   verifyURL: 'https://zksync2-mainnet-explorer.zksync.io/contract_verification'
    // },
  },
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  typechain: {
    outDir: "types",
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 21,
    enabled: process.env.REPORT_GAS ? true : false,
  },
  watcher: {
    compilation: {
      tasks: ["compile"],
    },
  },
};

export default config;
