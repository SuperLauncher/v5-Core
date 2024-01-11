import { ethers } from "hardhat";

async function main() {
  // Initialize the wallet.
  const accounts = await ethers.getSigners();

  const deployer = accounts[0];
  const configurator = accounts[0];
  const controller = accounts[0];

  console.log(`deployer: ${deployer.address}`);
  console.log(`configurator: ${configurator.address}`);
  console.log(`controller: ${controller.address}`);

  // Contracts
  const SaleManagerFactory = await ethers.getContractFactory("Manager");
  const SalesV5Factory = await ethers.getContractFactory("SalesV5Factory");
  const SalesV5 = await ethers.getContractFactory("SalesV5");

  // Manager
  let managerAddress = "0x84DE716521F950874d24Fe03BcD7465196Bd55Ca";

  let salesV5FactoryAddress = "";
  if (!salesV5FactoryAddress) {
    const salesV5Factory = await SalesV5Factory.connect(deployer).deploy(managerAddress);
    await salesV5Factory.deployed();
    salesV5FactoryAddress = salesV5Factory.address;
    console.log(`V5 Factory was deployed to ${salesV5FactoryAddress}`);

    const manager = await SaleManagerFactory.connect(deployer).attach(managerAddress);
    const tx = await manager.registerFactory(salesV5FactoryAddress);
    await tx.wait();
    console.log(`Manager registerFactory complete`);
  }

  // create campaign
  let campaignAddress = "";
  if (!campaignAddress) {
    const fcfsFactory = await SalesV5Factory.connect(deployer).attach(salesV5FactoryAddress);
    const tx = await fcfsFactory.create("TEST");
    await tx.wait();
    console.log(`Campaign created`);
  }

  const setup = true;
  if (campaignAddress && setup) {
    const campaign = await SalesV5.connect(configurator).attach(campaignAddress);

    campaign.setup(
      "", // currency
      [
        "1683288000", // time start
        "1683295200", // time end
      ],
      [
        //SoftCap, HardCap. In currency unit
        "",
        "",
      ],
      "160000000000000000", // unitPrice Price per 1e18 token
      "18",//tokenDpValue
      [
        //minMaxAlloc
        "100000000000000000000",
        "200000000000000000000",
      ],
      "100000000000000000", //insuranceDuration; // 0 means no insurance policy for this sale
      "" // tgeTime
    );
    console.log(`Campaign setup`);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
