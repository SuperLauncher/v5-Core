import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import BalanceTree from "../test/helpers/balance-tree";
import { eContractid } from "../test/helpers/types";

async function main() {
    // mock data
    const regAddress = '';
    const id = 0;

    const Registration = await ethers.getContractFactory(eContractid.RegisterIdo);
    const registration = await Registration.attach(regAddress);
    const [length, addresses, amounts] = (await registration.exportAll(id)) as [BigNumber, string[], BigNumber[]];
    
    if(length.isZero()) {
        console.log('no data')
        return;
    }

    const regData = addresses.map((address, index) => ({
      account: address, 
      amount: amounts[index]
   }));

    const balanceTree = new BalanceTree(regData);

    console.log('root', balanceTree.getHexRoot());
    
    const proofs = regData.map(item => ({
      amount: item.amount.toString(),
      address: item.account.toString(),
      proof: balanceTree.getProof(item.account, item.amount),
    }));

    var fs = require('fs');
    fs.writeFileSync('registrationMerkelTree.json', JSON.stringify(proofs));
    console.log("ok");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
