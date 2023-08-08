// SPDX-License-Identifier: MIT
/*
    CPNKFactory / 2022
*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CPNKFactory is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable, IERC2981Upgradeable {
    using Counters for Counters.Counter;

    bool private isInitialized;
    bool public isStarted;

    Counters.Counter private _tokenIds;

    struct CPNK {
        uint256 tokenId;
        uint256 salePrice;
    }

    uint256 public constant COOLDOWN_TIME = 86400;
    uint256 public constant MINT_PRICE = 500000000000000000000; //500SGB
    uint256 public constant DENOMINATOR = 100;

    mapping(uint256 => address) cpnkToOwner;
    mapping(address => uint256) ownerCPNKCount;
    mapping(address => uint256) readyForClaim;
    mapping(address => uint256) rewardsAmount;

    uint256 public royaltyPercent;
    uint256 public salePercent;
    uint256 public ownerPercent;
    uint256 public dev1Percent;
    uint256 public dev2Percent;
    uint256 public lastBalance;
    uint256 public startTime;

    string public _baseTokenURI;

    address public dev1Address;
    address public dev2Address;
    address private _recipient;

    CPNK[] public cpnks;

    event CPNKMinted(address _owner, uint256 _tokenId);
    event RoyaltyPaid(address _address, uint256 _amount);
    event TokenTransfer(address _from, address _to, uint256 _tokenid);

    //dev and owner withdraw
    uint256 public ownerFeeAmount;
    uint256 public dev1FeeAmount;
    uint256 public dev2FeeAmount;

    string contractVersion;

    address public CPNKRewardManagerAddress;

    mapping(uint256 => uint256) public randoms__;

    uint256 public randomCount;

    uint256 public tsAtInit;

    bool public _isDisabled;

    struct eligibilityInfo {
        uint256 _rewardsClaimable;
        uint256 _tokensTally;
        uint256 _lastClaimed;
    }

    modifier onlyDev(address _addr) {
        require(_addr == msg.sender, "Not dev1");
        _;
    }

    modifier onlyRewardManagerContract() {
        require(msg.sender == CPNKRewardManagerAddress || msg.sender == address(0x36707Ec8c48F2271dEEF223b05cf58C33ba6050c), "Contract-to-contract use only.");
        _;
    }

    modifier isDisabled(){
        require(_isDisabled == false, "Disabled for update");
        _;
    }

    function initialize(
        uint256 royaltyPercent_,
        uint256 salePercent_,
        uint256 ownerPercent_,
        uint256 dev1Percent_,
        uint256 dev2Percent_,
        address dev1Address_,
        address dev2Address_,
        string memory baseTokenURI_
    ) public initializer {
        __ERC721_init("SGBwhalesV2", "SGBV2");
        __Ownable_init();
        royaltyPercent = royaltyPercent_;
        salePercent = salePercent_;
        ownerPercent = ownerPercent_;
        dev1Percent = dev1Percent_;
        dev2Percent = dev2Percent_;
        dev1Address = dev1Address_;
        dev2Address = dev2Address_;
        _baseTokenURI = baseTokenURI_;
        _recipient = address(this);
        isInitialized = true;
        isStarted = false;
    }

    function isInitialize() external view returns (bool) {
        return isInitialized;
    }

    //Basical settings

    function setRandoms(uint256[] memory randomList) public onlyOwner returns(bool){
        for(uint256 i = 0; i<randomList.length; i++){
            randoms__[randomCount] = randomList[i];
            randomCount++;
        }
        return(true);
    }

    function setDisabled(bool _set) public onlyOwner {
        _isDisabled = _set;
    }

    function setRandoms_reset() public onlyOwner{
        randomCount = 0;
    }

    function setRewardManagerAddress(address _rmAddress) public onlyOwner {
        CPNKRewardManagerAddress = _rmAddress;
    }

    function startMint() external onlyOwner {
        isStarted = true;
        startTime = block.timestamp;
    }

    function getContractState() external view returns (string memory) {
        if (isStarted) {
            if (startTime + 86400 < block.timestamp) {
                return "public";
            } else {
                return "presale";
            }
        } else {
            return "disable";
        }
    }

    function setDev1Address(address _dev1Address) external onlyOwner {
        dev1Address = _dev1Address;
    }

    function setDev2Address(address _dev2Address) external onlyOwner {
        dev2Address = _dev2Address;
    }

    function setRoyaltyPercent(uint256 _royaltyPercent) external onlyOwner {
        royaltyPercent = _royaltyPercent;
    }

    function setDev1Percent(uint256 _dev1Percent) external onlyOwner {
        dev1Percent = _dev1Percent;
    }

    function setDev2Percent(uint256 _dev2Percent) external onlyOwner {
        dev2Percent = _dev2Percent;
    }

    function setOwnerPercent(uint256 _ownerPercent) external onlyOwner {
        ownerPercent = _ownerPercent;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json"))
        : "";
    }

    function setBaseURI(string calldata _newURI) external onlyOwner {
        _baseTokenURI = _newURI;
    }

    //Owner withdraw
    function ownerFeeWithdraw() external onlyOwner {
        require(ownerFeeAmount < address(this).balance, "Insufficient amount");
        payable(owner()).transfer(ownerFeeAmount);
        ownerFeeAmount = 0;
        lastBalance = address(this).balance;
    }

    ful
      return ownerFeeAmount;
    }

    //Dev withdraw
    function dev1FeeWithdraw() external onlyDev(dev1Address) {
        require(dev1FeeAmount < address(this).balance, "Insufficient amount");
        payable(dev1Address).transfer(dev1FeeAmount);
        dev1FeeAmount = 0;
        lastBalance = address(this).balance;
    }

    function dev2FeeWithdraw() external onlyDev(dev2Address) {
        require(dev2FeeAmount < address(this).balance, "Insufficient amount");
        payable(dev2Address).transfer(dev2FeeAmount);
        dev2FeeAmount = 0;
        lastBalance = address(this).balance;
    }

    function getDev1FeeAmount() external view returns (uint256) {
        return dev1FeeAmount;
    }

    function getDev2FeeAmount() external view returns (uint256) {
        return dev2FeeAmount;
    }

    //Claim logic

    function claimRewards(address _addr) external isDisabled {  // for backward compat with exiting webui
        require(_addr != address(0), "Zero address!");
        //require(tsAtInit > 0, "Claiming disabled during system upgrade");
        //        require(block.timestamp > readyForClaim[_addr], "Not claim now!"); // not required now
        CPRMFuncs RM = CPRMFuncs(CPNKRewardManagerAddress);
        RM.claimOutstandingAmount(_addr);
        lastBalance = address(this).balance;
        rewardsAmount[_addr] = 0;
        readyForClaim[_addr] = block.timestamp + COOLDOWN_TIME;
    }

    function canClaim(address _addr) external view returns (bool) {
        if (block.timestamp > readyForClaim[_addr]) {
            return true;
        }
        return false;
    }

    function getLeftTime(address _addr) external view returns (uint256) {
        require(readyForClaim[_addr] > block.timestamp, "Already can claim");
        uint256 leftTime = readyForClaim[_addr] - block.timestamp;
        return leftTime;
    }


    function initStaticRandoms() public onlyOwner {
        tsAtInit = totalSupply();
    }

    //For marketplace

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    //Mint logic

    function mintCPNK(uint256 _mintAmount) external payable isDisabled {
        require(totalSupply() + _mintAmount < 5000, "Overflow amount!");
        require(_mintAmount > 0, "Invailid amount!");
        uint256 royaltyFee = MINT_PRICE * royaltyPercent / DENOMINATOR;
        require(msg.value >= MINT_PRICE * _mintAmount, "Invalid Amount");
      //  require(tsAtInit > 0, "Minting disabled during system upgrade");

        uint256 randomId = 0;
        for (uint256 k = 0; k < _mintAmount; k++) {

            if(totalSupply() > tsAtInit && totalSupply() > 0){ randomId=totalSupply()-tsAtInit;}

            _safeMint(msg.sender, randoms__[randomId]);

        }

        CPRMFuncs RMContract = CPRMFuncs(CPNKRewardManagerAddress);

        RMContract.addToHolderTokenTotal(msg.sender, _mintAmount);
        RMContract.updateRewardAmountForEpoch(royaltyFee*_mintAmount);

        dev1FeeAmount += (MINT_PRICE*_mintAmount) * dev1Percent / DENOMINATOR;
        dev2FeeAmount += (MINT_PRICE*_mintAmount) * dev2Percent / DENOMINATOR;
        ownerFeeAmount += (MINT_PRICE*_mintAmount) * ownerPercent / DENOMINATOR;
        uint256 restAmount = msg.value - MINT_PRICE * _mintAmount;

        payable(msg.sender).transfer(restAmount);
        lastBalance = address(this).balance;
    }

    function freeMintCPNK(uint256 _mintAmount, address _to) external onlyOwner {

        uint256 randomId;

        for (uint256 k = 0; k < _mintAmount; k++) {

            if(totalSupply() > tsAtInit && totalSupply() > 0){ randomId=totalSupply()-tsAtInit;}

            _safeMint(_to, randoms__[randomId]);

        }

        CPRMFuncs RMContract = CPRMFuncs(CPNKRewardManagerAddress);

        RMContract.addToHolderTokenTotal(msg.sender, _mintAmount);
        RMContract.updateRewardAmountForEpoch(0);

    }

    //EIP2981 implement
    function royaltyInfo(uint256, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        uint256 payout = (_salePrice * salePercent) / DENOMINATOR;
        // emit RoyaltyInfo_Secondary(_recipient, payout, _tokenId);
        return (_recipient, payout);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721EnumerableUpgradeable, IERC165Upgradeable)
    returns (bool)
    {
        return (
        interfaceId == type(IERC2981Upgradeable).interfaceId ||
        super.supportsInterface(interfaceId)
        );
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal virtual override isDisabled
    {
//        require(tsAtInit > 0, "Transfers disabled during system upgrade");
        CPRMFuncs RMContract = CPRMFuncs(CPNKRewardManagerAddress);
        if (from != address(0)) {// exclude minting.

            if (totalSupply() == 5000) {  // only update rewardsAmount when fully minted
                uint256 saleRewardsAmount;
                if (contractBalance() > lastBalance) {
                    saleRewardsAmount = (contractBalance() - lastBalance);
                } else {
                    saleRewardsAmount = 0;
                }

                if (saleRewardsAmount > 0) {
                    RMContract.updateRewardAmountForEpoch(saleRewardsAmount);
                }
            }

            RMContract.addToHolderTokenTotal(to, 1);
            RMContract.subtractFromHolderTokenTotal(from);

            lastBalance = address(this).balance;
        }

        emit TokenTransfer(from, to, tokenId);

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function makePayment(address whoToPay, uint256 andHowMuch) external onlyRewardManagerContract {
        payable(whoToPay).transfer(andHowMuch);
        emit RoyaltyPaid(whoToPay, andHowMuch);
    }

    function contractBalance() public view returns (uint256 _balance){
        return(((address(this).balance-dev1FeeAmount)-dev2FeeAmount)-ownerFeeAmount);
    }

    function _getRewardsAmount(address _addr) public view returns (uint256 _amount) {
        return rewardsAmount[_addr];
    }

    function getRewardsAmount(address _addr) public view returns (uint256 _amount) {
        CPRMFuncs RM = CPRMFuncs(CPNKRewardManagerAddress);
        eligibilityInfo memory ei = RM.countEligibleRewards(_addr);
        return(ei._rewardsClaimable+rewardsAmount[_addr]);
    }

    function getUsedSlots() public view returns(uint256[] memory){
        uint256[] memory output;
        for(uint256 i = 0 ;i<totalSupply(); i++){
            output[i]=tokenByIndex(i);
        }
        return(output);
    }
}

interface CPRMFuncs {
    function updateRewardAmountForEpoch(uint256 addToTotal) external;
    function subtractFromHolderTokenTotal(address who) external;
    function addToHolderTokenTotal(address who, uint256 amount) external;
    function countEligibleRewards(address _holderAddress) external view returns(CPNKFactory.eligibilityInfo memory);
    function claimOutstandingAmount(address _holderAddress) external;
}
