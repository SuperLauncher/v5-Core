import { ethers } from "hardhat";

async function main() {
  // Initialize the wallet.
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const configurator = accounts[0];

  // Contracts
  const RolesRegistryFactory = await ethers.getContractFactory("RolesRegistry");
  const rolesRegistry = await RolesRegistryFactory.connect(deployer).deploy();
  await rolesRegistry.deployed();

  console.log(`RolesRegistry was deployed to ${rolesRegistry.address}`);

  // Setup Roles Registry
  await rolesRegistry.setDeployer(deployer.address, true);
  await rolesRegistry.setConfigurator(configurator.address, true);
  await rolesRegistry.setApprover(deployer.address, true);
  await rolesRegistry.setTallyHandler(deployer.address, true);
  console.log(`RolesRegistry setup complete`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
