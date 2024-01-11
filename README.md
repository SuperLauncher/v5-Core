# V5 Project

Install dependencies

```shell
yarn
```

Compile project

```shell
yarn compile
```

Unit Tests

```shell
yarn test
```

Deploy task to mainnet

```shell
npx hardhat run .\scripts\deploy-xxx.ts --network zkSyncMainnet 
npx hardhat run .\scripts\deploy-xxx.ts --network zkSyncMainnet 
```

Verify contracts

```shell
yarn hardhat verify --network zkSyncTestnet <contract address>
```

Verify contracts with parametters

```shell
yarn hardhat verify --network zkSyncTestnet <contract address> --constructor-args arguments.js
```