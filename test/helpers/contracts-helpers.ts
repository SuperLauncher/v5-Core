import { waitForTx, parseTokenWithDP, txOptions, getCurrentBlock, timeLatest } from './misc-utils';
import { Contract, Signer } from 'ethers';
import { ethers } from 'hardhat';
import { eContractid, tEthereumAddress } from './types';
import BigNumber from 'bignumber.js';
import { MintableToken } from '../../types/contracts/sale-common/mocks/MintableToken';
import { DataLogger, RolesRegistry, TestLaunch, TestSvLaunch } from '../../types';

export const deployContract = async <ContractType extends Contract>(
	contractName: string,
	args: any[],
	slug: string = '',
	signer?: Signer
): Promise<ContractType> => {
	console.log('Deploying: ' + contractName);
	const contract = (await (await ethers.getContractFactory(contractName, signer)).deploy(
		...args
	)) as ContractType;

	return contract;
};

export const deployMintableToken = async (name: string, symbol: string, dp: string) => {
	const args: string[] = [
		name,
		symbol,
		dp,
	];
	const instance = await deployContract<MintableToken>("MintableToken", args);
	return instance;
}

export const deployLaunch = async () => {
	const instance = await deployContract<TestLaunch>(eContractid.Launch, []);
	return instance;
}

export const deploySvLaunch = async () => {
	const instance = await deployContract<TestSvLaunch>(eContractid.Egg, []);
	return instance;
}

export const deployRole = async () => {
	const instance = await deployContract<RolesRegistry>(eContractid.Role, []);
	return instance;
}

export const deployDataLogger = async (rolesRegistry: tEthereumAddress) => {
	const args: string[] = [
		rolesRegistry,
	];
	const instance = await deployContract<DataLogger>("DataLogger", args);
	return instance;
}
