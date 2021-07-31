// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

interface ICrossChain {
    function setAcceptToken(address token, bool isAccepted) external;
    function setAcceptChain(uint8 chain, bool isAccepted) external;
    function addRelayer(address relayerAddress) external;
    function removeRelayer(address relayerAddress) external;
    function setConfirmRequireNum(uint256 requireNum) external;
    function setMaxAmountPerDay(address token, uint256 amount) external;
    function setFee(uint8 chain, uint256 amount) external;
    function crossChainTransfer(address token, uint256 amount, address to, uint8 chain) external payable;
    function receiveToken(address token, uint256 amount, address receiveAddress, string memory info) external;
    function transferToken(address token, uint256 amount, address to) external;
    function transfer(uint256 amount, address payable to) external;
    function pause() external;
    function unpause() external;
}