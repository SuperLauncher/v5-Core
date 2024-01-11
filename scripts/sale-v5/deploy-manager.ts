import { ethers } from "hardhat";

async function main() {
  // Initialize the wallet.
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const controller = accounts[0];

  // Data Logger
  const DataLoggerFactory = await ethers.getContractFactory("DataLogger");
  const dataLogger = await DataLoggerFactory.connect(deployer).deploy(controller.address);
  await dataLogger.deployed();

  // Roles Registry
  const rolesRegistryAddress = "0xDF9323040bA12D1b594E0Fa4a3f72a57c522fB59";
  //Dao
  const DAO = deployer.address;
  // Contracts
  const SaleManagerFactory = await ethers.getContractFactory("Manager");
  const saleManager = await SaleManagerFactory.connect(deployer).deploy(
    rolesRegistryAddress,
    dataLogger.address,
    DAO
  );
  await saleManager.deployed();
  console.log(`Manager was deployed to ${saleManager.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
