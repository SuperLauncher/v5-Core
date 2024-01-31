// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../base/Base.sol";
import "../../base/Fillability.sol";

contract SalesV5 is Fillability, Base {

    struct Config {
        address currency;   // eg: USDT //        
        uint[2] times;      // Start, End time
        uint[2] caps;       // SoftCap, HardCap. In currency unit
        uint unitPrice;     // Price per 1e18 token
        uint tokenDpValue;
        uint currencyDpValue;
        uint[2] minMaxAlloc; // Min, Max, 
        uint extraAllocRate; // Extra allocation for svLaunch. 0 means no extra allocation.
                             // Eg: Rate = 1e18 means, every 1e18 svLaunch (1 svLAunch) will get 1 USDT (ie, 1*currencyDpValue) extra allocation to max. 
                             // Eg: Rate = 1e19 means, every 10e18 svLaunch (1 svLAunch) will get 1 USDT (ie, 1*currencyDpValue) extra allocation to max.


        // This will be set during finishUpTge call
        uint tgeTime;
    }

    // The server will use the user's svLaunch and insurance info to tally the fill.
    struct Buys {
        uint[] items;
        uint totalBought;
    }

    struct Sales {
        mapping(address => Buys) buysMap;
        address[] buyerList;
        uint totalFundRaised;
    }

    struct Claim {
        uint totalRefunded; // Full purchase (if sale cancelled), or sum of unfilled + insurance claimed.
        uint insuranceRefunded;
        bool fullRefunded;
        bool partialFillRefunded;
        bool insuranceClaimed;
    }

    struct Claims {
        mapping(address => Claim) claimMap;
        InsuranceClaim insurance;
    }

    struct InsuranceClaim {
        uint total;
        uint count;
    }

    struct Tally {
        bytes32 merkleRoot;
    }

    Config private _config;
    Sales private _sales;
    Claims private _claims;
    Tally private _tally;

    address private immutable _officialSigner;

    event Buy(address indexed user, uint cost);
    event Refund(address indexed user, uint amount);
    event FundIn(address from, uint amount);
    event DaoRetrieveFund(uint amount);
    event FundOutUnSold(uint amount);

    constructor(IManager mgr) Base(mgr) {
        _officialSigner = mgr.getOfficialSigner();
    }

    function setup(
         address currency, 
        uint[2] memory times, 
        uint[2] memory caps, 
        uint unitPrice, 
        uint tokenDp, 
        uint[2] memory minMaxAlloc,
        uint extraAllocRate,
        uint insuranceDuration) canConfigure external 
    {
        _requireNonZero(currency);
        _require(block.timestamp < times[0] && times[0] < times[1], "Invalid times");
        _require(caps[1] > 0 && caps[0] <= caps[1] && unitPrice > 0 && tokenDp > 0, "Invalid params");
        _require(minMaxAlloc[0] > 0 && minMaxAlloc[1] > 0 && minMaxAlloc[0] <= minMaxAlloc[1], "Invalid alloc");
        _require(insuranceDuration <= Constant.MAX_INSURANCE_DURATION, "Exceed max insurance duration");
        _config.currency = currency;
        _config.caps = caps;
        _config.unitPrice = unitPrice;
        _config.tokenDpValue = 10 ** tokenDp;
        _config.currencyDpValue = _getDpValue(currency);
        _config.times = times;
        _config.minMaxAlloc = minMaxAlloc;
        _config.extraAllocRate = extraAllocRate;

    
        _setState(State.Configured, true);
        _configInsurance(insuranceDuration);
        _configFillability(caps[1]);
        emit Setup(msg.sender);
    }

    // Users are able to buy until the end of sale, even if the hardCap is met.
    function buyToken(uint fund, uint svLaunch, bytes memory signature) external notPaused nonReentrant {
        _require(isLive() && fund > 0, "Not live or Invalid amount");
    
        if (!_verifySvLaunch(msg.sender, svLaunch, signature)) {
            svLaunch = 0;
        }

        if (svLaunch >= Constant.MIN_QUALIFY_SV_LAUNCH) {
            _pushFillabilityData(svLaunch, fund);
        }

        (uint min, , , , uint allocLeft) = getAllocation(msg.sender, svLaunch);
        _require(allocLeft > 0 && fund <= allocLeft, "No alloc left or exceed alloc");
      
        // Check min purchase
        if (allocLeft >= min) {
            require(fund >= min, "Cannot buy less than min");
        } else {
            // Must buy the remaining small amount
            require(fund == allocLeft, "Must buy remaining small amount");
        }
        _transferTokenIn(_config.currency, fund);
        
        // Record user's Purchase
        Buys storage buys = _sales.buysMap[msg.sender];

         // New buyer ?
        if (buys.totalBought == 0) {
            _sales.buyerList.push(msg.sender);
        }
        buys.items.push(fund);
        buys.totalBought += fund;
        _sales.totalFundRaised += fund;

        _log(DataAction.Buy, fund, 0);
        emit Buy(msg.sender, fund);
    }


    //-----------------------------------------------------------//
    //   EXTERNAL FUNCTIONS WITH ROLE-ACCESS RIGHT REQUIREMENT   //
    //-----------------------------------------------------------//

    function fundIn(address from, uint amountToVerify) external onlyDeployer notPaused {
        
        // Can only be called after SuperCerts is setup with a valid asset token address
        address asset = _getAssetTokenAddress();
        _require(asset != Constant.ZERO, "Cert not setup yet");
        
        uint amountNeeded = getTokenQty(_config.caps[1]);
        _require(amountToVerify == amountNeeded, "Wrong amount");

       _transferTokenFrom(asset, amountNeeded, from, address(this));
       emit FundIn(from, amountNeeded);
    }
    
    function tally(bytes32 root) external onlyTallyHandler notPaused {

        _require(!isTallied(), "Already tallied");
        _require(block.timestamp > _config.times[1], "Sale not yet end");

        // At the time of tally, if softcap is not met, the sale is failed.
        if (!metSoftCap()) {
            _setState(State.Failed, true);
            _setPause(true);
            _setReturnable(true);
            emit Failed();
        } else {
            _tally.merkleRoot = root;
            _setState(State.Tallied, true);
            emit Tallied(msg.sender, root);
        }
    }

    // A user can either get their fund returned, in case of a pause and return
    // Or a user can claim their cert (with or w/o insurance) or an unfill refund.
    // userAction()

    function processReturnFund() external canReturnFund nonReentrant {

        (Buys storage buys, Claim storage claim) = _getUserStats(msg.sender);
        _require(!claim.fullRefunded && claim.totalRefunded==0, "Already fully refunded");
        
        uint amount = buys.totalBought; // Process a full refund anytime if sale is paused & refundable
        _require(amount > 0, "Did not buy");

        claim.fullRefunded = true;
        claim.totalRefunded = amount;
        
        _transferTokenOut(_config.currency, amount, msg.sender);

        _log(DataAction.Refund, amount, 0);
        emit Refund(msg.sender, amount);
    }

    function processClaim(bytes32[] calldata merkleProof, uint bought, uint filled, uint insurance, bool exerciseInsure) external notPaused nonReentrant {
        
        _require(isTallied() && isTge(), "Not ready");
        bool certClaimed = hasClaimedCerts(msg.sender);
        _require(!certClaimed, "Cert already claimed");

        // Prove purchase
        (bought, filled, insurance) = _getFillInfo(merkleProof, bought, filled, insurance);
        _require(bought > 0, "Did not buy");

        (, Claim storage claim) = _getUserStats(msg.sender);
        _require(!claim.fullRefunded, "Already fully refunded");

        // Process unfilled refund
        uint refund;
        if (!claim.partialFillRefunded && (bought > filled)) {
            claim.partialFillRefunded = true;
            refund = (bought - filled); // Refund the unfilled portion
        }
    
        // Process insurance claim if enabled & exercised
        if (getInsuranceDuration() > 0 && insurance > 0 && !claim.insuranceClaimed && exerciseInsure) {
                
            (bool inPeriod, , ,) = isInsuranceWindow();
            _require(inPeriod, "Not within insurance window");
            uint amtInsured = _min(filled, insurance);
            claim.insuranceClaimed = true;
            claim.insuranceRefunded = amtInsured;
            _claims.insurance.total += amtInsured;
            _claims.insurance.count++;
            refund += amtInsured;
        }

        if (refund > 0) {
            claim.totalRefunded = refund;
            _transferTokenOut(_config.currency, refund, msg.sender);

            _log(DataAction.Refund, refund, 0);
            emit Refund(msg.sender, refund);
        }

        // Proceed to Claim Certs
        if (filled > claim.insuranceRefunded) {
            
            (address certAddress, bool enabled) = getCertsInfo();
            _require(certAddress != Constant.ZERO && enabled, "Invalid or cert not enabled");

            uint certAmount = filled - claim.insuranceRefunded;
            _require(certAmount > 0, "No entitlement");
            uint totalEntitlement = getTokenQty(certAmount);
            _require(_claimCerts(msg.sender, totalEntitlement), "Already Claimed");

            _log(DataAction.ClaimCerts, totalEntitlement, 0);
        }
    }

    function isInsuranceWindow() public view returns (bool inPeriod, bool passedPeriod, uint start, uint end) {
        if (isTge()) {
            return _isInsuranceWindow(_config.tgeTime);
        }
    }

    function finishUpTge() external onlyDeployer {
        _require(isTallied() && !isTge(), "Not yet tally or has already Tge");
        _setState(State.Tge, true);
        _config.tgeTime = block.timestamp;
         emit Tge(msg.sender);
    }

    // After the insurance window, the Dao can proceed to send the sale's fund to Dao MS address for further processing.
    // At the same time, any unsold tokens can be sent back to dao address for further processing.
    function daoRetrieveFund() external onlyDeployer {

        // If insurance is enabled, can only retrieve fund N days after TGE
        if (getInsuranceDuration() > 0) {
            (, bool passedPeriod, , ) = isInsuranceWindow();
            _require(passedPeriod, "Not yet ready");
        }

        // Calculate the amount of fund to be sent to Dao MultiSig
        uint amount = _min(_config.caps[1], _sales.totalFundRaised) - _claims.insurance.total;
        address dao = _manager.getDaoMultiSig();
        _transferTokenOut(_config.currency, amount, dao);
        emit DaoRetrieveFund(amount);

        // Calculate the amount of unsold tokens to be set to Dao MultiSig
        address asset = _getAssetTokenAddress();
        if (asset != Constant.ZERO) {
            // Cert is setup and enabled
             uint unSold;
            if (_sales.totalFundRaised < _config.caps[1]) {
                unSold = _config.caps[1] - _sales.totalFundRaised;
            }

            // Adds insurance refunded
            unSold += _claims.insurance.total;
        
            if (unSold > 0) {
                amount = getTokenQty(unSold);
                _transferTokenOut(asset, amount, dao);
                emit FundOutUnSold(amount);
            }
        }
    }

    // This should be called to calculate the data needed for Tally().
    function exportAll() external onlyConfigurator view returns (uint, address[] memory, uint[] memory) {

        uint len =  _sales.buyerList.length;
        address[] memory add = new address[](len);
        uint[] memory amounts = new uint[](len);

        address tmp;
        for (uint n = 0; n < len; n++) {
            tmp = _sales.buyerList[n];
            add[n] = tmp;
            amounts[n] = _sales.buysMap[tmp].totalBought;
        }
        return (len, add, amounts);
    }

    function export(uint from, uint to) external onlyConfigurator view returns (uint, address[] memory, uint[] memory) {
        
        uint len =  _sales.buyerList.length;
        require(len > 0  && from <= to, "Invalid range");
        require(to < len, "Out of range");

        uint count = to - from + 1;

        address[] memory add = new address[](count);
        uint[] memory amounts = new uint[](count);

        address tmp;
        for (uint n = 0; n < count; n++) {
            tmp = _sales.buyerList[n + from];
            add[n] = tmp;
            amounts[n] = _sales.buysMap[tmp].totalBought;
        }
        return (count, add, amounts);
    }


    //--------------------------------//
    //   EXTERNAL, PUBLIC  FUNCTIONS  //
    //--------------------------------//

    function isLive() public view returns(bool) {
        return (block.timestamp < _config.times[1] && block.timestamp >= _config.times[0]);
    }

    function getAllocation(address user, uint svLaunch) public view returns(uint min, uint max, uint extra, uint bought, uint allocLeft) {
        min = _config.minMaxAlloc[0];
        max = _config.minMaxAlloc[1];
        
        if (svLaunch >= Constant.MIN_QUALIFY_SV_LAUNCH) {
            extra = (svLaunch * _config.currencyDpValue) / _config.extraAllocRate;
        }

        bought = _sales.buysMap[user].totalBought;
        allocLeft = max + extra - bought;
    }

    function getRaisedAmount() public view returns(uint) {
        return _sales.totalFundRaised;
    }

    function getBuyersCount() external view returns (uint) {
       return _sales.buyerList.length;
    }

    function metSoftCap() public  view returns (bool) {
        return _sales.totalFundRaised >= _config.caps[0];
    }

    function getTokenQty(uint fund) public view returns (uint) {
        return ((fund * _config.tokenDpValue) / _config.unitPrice);
    }

    function getInfoForTally() external view returns (uint endTime, uint softCap, uint hardCap) {
        endTime = _config.times[1];
        softCap = _config.caps[0];
        hardCap = _config.caps[1];
    }
    
    function getConfig() external view returns (Config memory) {
        return _config;
    }

    function getUserClaim(address user) external view returns (Claim memory) {
        return _claims.claimMap[user];
    }

    //----------------------//
    //   PRIVATE FUNCTIONS  //
    //----------------------//
    function _getUserStats(address user) private view returns (Buys storage, Claim storage) {
        return (_sales.buysMap[user], _claims.claimMap[user]);
    }

    function _getFillInfo(bytes32[] calldata merkleProof, uint bought, uint filled, uint insurance) private view returns (uint, uint, uint) {

        bytes32 node = keccak256(abi.encodePacked(msg.sender, bought, filled, insurance));
        bool proofOk =  MerkleProof.verify(merkleProof, _tally.merkleRoot, node);
        bool totalOk = _sales.buysMap[msg.sender].totalBought == bought;
        return proofOk && totalOk ? (bought, filled, insurance) : (0,0,0);
    }

    function _verifySvLaunch(address user, uint svAmount, bytes memory signature) private view returns (bool) {
        bytes32 hash =  keccak256(abi.encodePacked(this, user, svAmount));
        return _verifyHash(hash, signature);
    }

     function _verifyHash(bytes32 hash, bytes memory signature) private view returns (bool) {
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(Constant.ETH_SIGN_PREFIX, hash));
        address signer = _recover(prefixedHashMessage, signature);
        return (signer == _officialSigner);
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function _recover(bytes32 hash, bytes memory sig) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    function _log(DataAction action, uint a, uint b) private {
         _manager.logData(msg.sender, DataSource.Campaign, action, a, b);
    }
}
