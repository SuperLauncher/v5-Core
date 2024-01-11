import { ethers } from "hardhat";

async function main() {
    const controler = '0x75C06f033e7Cd5B370b88039c32D3455C056E665';
    const DataLogger = await ethers.getContractFactory("DataLogger");
    console.log(`Running deploy script for the DataLogger contract`);

    const instance = await DataLogger.deploy(controler);
    await instance.deployed();

    const contractAddress = instance.address;
    console.log(`${instance.contractName} was deployed to ${contractAddress}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
