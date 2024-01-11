import BigNumber from 'bignumber.js';


export enum eContractid {
	Utils = 'Utils',
	Launch = 'TestLaunch',
	Egg = 'TestEgg',
	SvLaunch = 'TestSvLaunch',
	ParametersProvider = 'ParametersProvider',
	Governance = 'Governance',
	Proposals = 'Proposals',
	ProposalsEvmExecutor = 'ProposalsEvmExecutor',
	RegisterIdo = 'RegisterIdo',
	EggPoolStaking = 'EggPoolStaking',
	RolesRegistry = 'RolesRegistry',
	Manager = 'IdoManager',
	Role = 'RolesRegistry',
	IdoCampaign = 'IdoCampaign',
        OtcManager= 'OtcManager',
        OtcCampaign = 'OtcCampaign',
}

export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
export const SALE_ROLE = '0x9E55c21f55849d6FBDc89416af34D70668cAA183';
export const TREASURY = '0xb723C8fc68f33d5E92411BB981124420de530aAA';
export const REFERRAL_TREASURY = '0xb723C8fc68f33d5E92411BB981124420de530aAA';

export type tEthereumAddress = string;
export type tStringTokenBigUnits = string; // 1 ETH, or 10e6 USDC or 10e18 DAI
export type tBigNumberTokenBigUnits = BigNumber;
// 1 wei, or 1 basic unit of USDC, or 1 basic unit of DAI
export type tStringTokenSmallUnits = string;
export type tBigNumberTokenSmallUnits = BigNumber;