// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "./IERC20CrossChain.sol";
import "./CrossChainStorage.sol";

contract CrossChain is CrossChainStorage {

    enum Error {
        NO_ERROR,
        ALREADY_RELAYED,
        OVER_MAX_AMOUNT_PER_DAY
    }

    event Failure(uint256 error);

    uint256 constant secondsPerDay = 86400;

    event CrossChainTransfer(address indexed from, uint256 amount, address indexed token, address targetAddress, Chain chain, uint256 fee);
    event ReceivingToken(address indexed receiveAddress, address indexed token, uint256 amount, string info);
    event ReceiveTokenDone(address indexed receiveAddress, address indexed token, uint256 amount, string info);
    event Paused(address account);
    event Unpaused(address account);
    event AcceptToken(address token, bool isAccepted);
    event AcceptChain(Chain chain, bool isAccepted);
    event RelayerAdded(address relayer);
    event RelayerRemoved(address relayer);
    event ConfirmRequireNumChanged(uint256 oldNum,uint256 newNum);
    event MaxAmountChanged(address token, uint256 oldAmount, uint256 newAmount);
    event MinAmountChanged(address token, uint256 oldAmount, uint256 newAmount);
    event MaxAmountPerDayChanged(address token, uint256 oldMaxAmount, uint256 newMaxAmount);
    event FeeChanged(Chain chain, uint256 oldFee, uint256 newFee);

    constructor() {
        admin = msg.sender;
    }

    function initialize(
        address _acceptToken,
        uint256 _confirmRequireNum,
        Chain[] memory _acceptChains,
        uint256 _timestamp
    ) external  {
        require(admin == msg.sender, "UNAUTHORIZED");
        require(timestamp == 0, "ALREADY INITIALIZED");
        timestamp = _timestamp;
        confirmRequireNum = _confirmRequireNum;
        acceptToken[_acceptToken] = true;
        for(uint8 i = 0; i < _acceptChains.length; i++){
            acceptChain[_acceptChains[i]] = true;
        }
        paused = false;
    }

    function setAcceptToken(address token, bool isAccepted) external onlyOwner{
        acceptToken[token] = isAccepted;
        emit AcceptToken(token, isAccepted);
    }

    function setAcceptChain(Chain chain, bool isAccepted) external onlyOwner{
        acceptChain[chain] = isAccepted;
        emit AcceptChain(chain, isAccepted);
    }

    function addRelayer(address relayerAddress) external onlyAdmin{
        relayer[relayerAddress] = true;
        emit RelayerAdded(relayerAddress);
    }

    function removeRelayer(address relayerAddress) external onlyOwner{
        relayer[relayerAddress] = false;
        emit RelayerRemoved(relayerAddress);
    }

    function setConfirmRequireNum(uint256 requireNum) external onlyOwner{
        uint256 oldNum = confirmRequireNum;
        confirmRequireNum = requireNum;
        emit ConfirmRequireNumChanged(oldNum, requireNum);
    }

    function setMaxAmount(address token, uint256 amount) external onlyOwner{
        require(amount >= minAmount[token], "Invalid amount");
        uint256 oldAmount = maxAmount[token];
        maxAmount[token] = amount;
        emit MaxAmountChanged(token, oldAmount, amount);
    }

    function setMinAmount(address token, uint256 amount) external onlyOwner{
        require(amount <= maxAmount[token], "Invalid amount");
        uint256 oldAmount = minAmount[token];
        minAmount[token] = amount;
        emit MinAmountChanged(token, oldAmount, amount);
    }

    function setMaxAmountPerDay(address token, uint256 amount) external onlyOwner{
        uint256 oldMaxAmount = maxAmountPerDay[token];
        maxAmountPerDay[token] = amount;
        emit MaxAmountPerDayChanged(token, oldMaxAmount, amount);
    }

    function setFee(Chain chain, uint256 amount) external onlyOwner{
        uint256 oldFee = fee[chain];
        fee[chain] = amount;
        emit FeeChanged(chain, oldFee, amount);
    }
    
    function crossChainTransfer(address token, uint256 amount, address to, Chain chain) external payable whenNotPaused {
        require(acceptToken[token],"Invalid token");
        require(acceptChain[chain],"Invalid chain");
        require(msg.value >= fee[chain], "Fee is not enough");
        checkTransferAmount(token, amount);
        (Error error, uint256 totalAmount)= addTotalAmount(token, sendTotalAmount[token], amount);
        require(uint256(error) == 0, "Total amount is greater than max amount per day");
        sendTotalAmount[token] = totalAmount;

        sendTotalIndex[sendIndex] = CrossTransaction(msg.sender, to, amount, block.timestamp, chain, token);
        sendIndex++;
        IERC20CrossChain(token).transferFrom(msg.sender, address(this), amount);
        emit CrossChainTransfer(msg.sender, amount, token, to, chain, msg.value);
    }

    function getSendPool(uint256 start, uint256 end) external view 
        returns(
            address[] memory tokeneArr,
            address[] memory targetArr,
            uint256[] memory indexArr, 
            uint256[] memory amountArr,
            uint256[] memory chainArr
            )
     {
        require(end >= start, "wrong range");
        uint256 len = end - start;
        tokeneArr = new address[](len);
        targetArr = new address[](len);
        indexArr = new uint256[](len);
        amountArr = new uint256[](len);
        chainArr = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            indexArr[i] = start + i;
            CrossTransaction memory ct = sendTotalIndex[indexArr[i]];
            tokeneArr[i] = ct.token;
            targetArr[i] = ct.to;
            amountArr[i] = ct.value;
            chainArr[i] = uint256(ct.chain);
        } 
    }

    function receiveToken(address token, uint256 amount, address receiveAddress, string memory info) external onlyRelayer whenNotPaused returns (uint256){
        bytes32 relayInfoHash = keccak256((abi.encodePacked(token,receiveAddress,amount,info)));
        if(hasRelay(relayInfoHash)) return fail(Error.ALREADY_RELAYED);
        uint256 confirmNum = relayInfo[relayInfoHash].length;
        if(confirmNum == 0){
            (Error error, uint256 totalAmount) = addTotalAmount(token, receiveTotalAmount[token], amount);
            if(uint256(error) != 0) return fail(error);
            receiveTotalAmount[token] = totalAmount;
        }
        relayInfo[relayInfoHash].push(msg.sender);
        confirmNum = confirmNum + 1;
        if(confirmNum < confirmRequireNum){
            emit ReceivingToken(receiveAddress, token, amount, info);
        }else if(relayInfo[relayInfoHash].length == confirmRequireNum){
            IERC20CrossChain(token).transfer(receiveAddress, amount);
            emit ReceivingToken(receiveAddress, token, amount, info);
            emit ReceiveTokenDone(receiveAddress, token, amount, info);
        }
        return uint256(Error.NO_ERROR);
    }

    function transferToken(address token, uint256 amount, address to) external onlyAdmin {
        IERC20CrossChain(token).transfer(to, amount);
    }

    function transfer(uint256 amount, address payable to) external onlyOwner {
        to.transfer(amount);
    }

    function pause() external whenNotPaused onlyOwner {
         paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external whenPaused onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function checkTransferAmount(address token, uint256 amount) internal view {
        require(amount <= maxAmount[token],"Amount is greater than max amount");
        require(amount >= minAmount[token],"Amount is less than min amount");
    }

    function addTotalAmount(address token, uint256 totalAmount, uint256 amount) internal returns (Error,uint256) {
        if(block.timestamp > timestamp + secondsPerDay){
            uint256 offset = (block.timestamp-timestamp)/secondsPerDay*secondsPerDay;
            timestamp = timestamp + offset;
            totalAmount = 0;
        }
        totalAmount = totalAmount + amount;
        if(totalAmount > maxAmountPerDay[token]) return (Error.OVER_MAX_AMOUNT_PER_DAY, totalAmount);
        return (Error.NO_ERROR ,totalAmount);
    }

    function hasRelay(bytes32 relayInfoHash) internal view returns (bool){
        address[] memory relayers = relayInfo[relayInfoHash];
        for(uint256 i = 0; i < relayers.length; i++){
            if(relayers[i] == msg.sender)
                return true;
        }
        return false;
    }

    function fail(Error err) private returns (uint) {
        emit Failure(uint256(err));
        return uint256(err);
    }
}