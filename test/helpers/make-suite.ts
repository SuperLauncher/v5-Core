// import { MintableToken } from './../../types/MintableToken.d';
import {  deployMintableToken,deployRole } from './contracts-helpers';
import { evmRevert, evmSnapshot, waitForTx } from './misc-utils';
import { Signer } from 'ethers';
import { ethers } from 'hardhat';
import { tEthereumAddress } from './types';
import { MintableToken } from '../../types/contracts/sale-common/mocks/MintableToken';

export interface SignerWithAddress {
	signer: Signer;
	address: tEthereumAddress;
}
export interface TestEnv {
	admin: Signer,
	deployer: Signer,
	approver: Signer,
	configurator: Signer,
	users: SignerWithAddress[],
	WBNB: MintableToken,
	BUSD: MintableToken,
	USDT: MintableToken,
	BTC: MintableToken,
	XYZ: MintableToken,
}

const testEnv: TestEnv = {
	admin: {} as Signer,
	deployer: {} as Signer,
	approver: {} as Signer,
	configurator: {} as Signer,
	users: [] as SignerWithAddress[],
	WBNB: {} as MintableToken,
	BUSD: {} as MintableToken,
	USDT: {} as MintableToken,
	BTC: {} as MintableToken,
	XYZ: {} as MintableToken,
} as TestEnv;

let buidlerevmSnapshotId: string = '0x1';
const setBuidlerevmSnapshotId = (id: string) => {
	buidlerevmSnapshotId = id;
};


export async function initializeMakeSuite() {
	const [admin, deployer, configurator, approver, ...restSigners] = await ethers.getSigners();

	testEnv.admin = admin;
	testEnv.deployer = deployer;
	testEnv.approver = approver;
	testEnv.configurator = configurator;

	for (const signer of restSigners) {
		testEnv.users.push({
			signer,
			address: await signer.getAddress(),
		});
	}
	//deploy currencies
	const busd = await deployMintableToken("BUSD", "BUSD", "18");
	const usdt = await deployMintableToken("USDT", "USDT", "18");
	const btc = await deployMintableToken("BTC", "BTC", "18");
	testEnv.WBNB = await deployMintableToken("WBNB", "WBNB", "18");


	const bob = testEnv.users[0];
	const carol = testEnv.users[1];
	const alice = testEnv.users[2];

	testEnv.XYZ = await deployMintableToken("XYZ", "XYZ", '18');

	const role = await deployRole();

	await waitForTx(
		await role.setDeployer(deployer.address, true));
	await waitForTx(
		await role.setDeployer(admin.address, true));
	await waitForTx(
		await role.setConfigurator(configurator.address, true));
	await waitForTx(
		await role.setConfigurator(admin.address, true));
	await waitForTx(
		await role.setApprover(approver.address, true));
	await waitForTx(
		await role.setApprover(admin.address, true));
	testEnv.role = role;

	for (const signer of restSigners) {
		testEnv.users.push({
			signer,
			address: await signer.getAddress(),
		});
	}
	console.log("initializeMakeSuite complete");
}


export function makeSuite(name: string, tests: (testEnv: TestEnv) => void) {
	describe(name, () => {
		before(async () => {
			setBuidlerevmSnapshotId(await evmSnapshot());
		});
		tests(testEnv);
		after(async () => {
			await evmRevert(buidlerevmSnapshotId);
		});
	});
}
