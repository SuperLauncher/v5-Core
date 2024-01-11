// SPDX-License-Identifier: BUSL-1.1


pragma solidity 0.8.21;

library Constant {

    address public constant ZERO                                = address(0);
    uint    public constant E18                                 = 1e18;
    uint    public constant PCNT_100                            = 1e18;
    uint    public constant PCNT_50                             = 5e17;
    uint    public constant PCNT_5                              = 5e16;
    uint    public constant E12                                 = 1e12;
    uint    public constant MAX_INSURANCE_DURATION              = 10 days; 
    uint    public constant MIN_QUALIFY_SV_LAUNCH               = 100e18;
    bytes   public constant ETH_SIGN_PREFIX                     = "\x19Ethereum Signed Message:\n32";
  
}




