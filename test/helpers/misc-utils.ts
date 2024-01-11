import { BigNumber } from 'bignumber.js';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { ContractTransaction } from 'ethers';
import {ethers} from 'hardhat';

export let DRE: HardhatRuntimeEnvironment = {} as HardhatRuntimeEnvironment;

export const setDRE = (_DRE: HardhatRuntimeEnvironment) => {
	DRE = _DRE;
  };

export const evmSnapshot = async () => await ethers.provider.send('evm_snapshot', []);

export const evmRevert = async (id: string) => ethers.provider.send('evm_revert', [id]);

export const increaseTime = async (secondsToIncrease: number) =>
  await ethers.provider.send('evm_increaseTime', [secondsToIncrease]);

export const waitForTx = async (tx: ContractTransaction) => await tx.wait(1);

export const getCurrentBlock = async () => {
	return ethers.provider.getBlockNumber();
  };

  
export const timeLatest = async () => {
	const block = await ethers.provider.getBlock('latest');
	return new BigNumber(block.timestamp);
  };
  
  export const advanceBlock = async (timestamp: number) =>
  await ethers.provider.send('evm_mine', [timestamp]);

export const latestBlock = async () => ethers.provider.getBlockNumber();

export const advanceBlockTo = async (target: number) => {
	const currentBlock = await latestBlock();
	const start = Date.now();
	let notified;
	if (target < currentBlock)
	  throw Error(`Target block #(${target}) is lower than current block #(${currentBlock})`);
	// eslint-disable-next-line no-await-in-loop
	while ((await latestBlock()) < target) {
	  if (!notified && Date.now() - start >= 5000) {
		notified = true;
		console.log("advanceBlockTo: Advancing too many blocks is causing this test to be slow.'");
	  }
	  // eslint-disable-next-line no-await-in-loop
	  await advanceBlock(0);
	}
  };
  
export const increaseTimeAndMine = async (secondsToIncrease: number) => {
	await ethers.provider.send('evm_increaseTime', [secondsToIncrease]);
	await ethers.provider.send('evm_mine', []);
  };
  
export const PCNT_100 = new BigNumber("1").shiftedBy(6);
export const PCNT_10 = new BigNumber("1").shiftedBy(5);


export const parseTokenWithDP =
 (value: string,  dp: number) => {
	 return new BigNumber(value).shiftedBy(dp).toString();
}

//refer this issue: https://github.com/bosonprotocol/contracts/issues/255
export const maxTip = ethers.utils.parseUnits(
	process.env.MAX_TIP
	  ? String(process.env.MAX_TIP)
	  : "1"
	,"gwei");

export const txOptions = {maxPriorityFeePerGas: maxTip};