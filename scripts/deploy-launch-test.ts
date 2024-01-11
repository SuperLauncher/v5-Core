import { Wallet } from "zksync-web3";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import hre from 'hardhat';

async function main() {
    console.log(`Running deploy script for the TestLaunch contract`);

    // Initialize the wallet.
    const wallet = new Wallet(process.env.PRIVATE_KEY as string);

    const deployer = new Deployer(hre, wallet);
    const artifact = await deployer.loadArtifact("TestLaunch");

    const tokenContract = await deployer.deploy(artifact, []);
    const contractAddress = tokenContract.address;
    console.log(`${artifact.contractName} was deployed to ${contractAddress}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
