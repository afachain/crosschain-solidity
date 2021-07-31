// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "./CrossChainAdminStorage.sol";

contract CrossChainStorage is CrossChainAdminStorage{

    enum Chain {
        ETH, /// Ethereum
        BSC, /// Binance Smart Chain
        HECO /// Huobi ECO Chain
    }

    //uint256[6]
    struct CrossTransaction {
        address from;
        address to;
        uint256 value;
        uint256 createTime;
        Chain chain;
        address token;
        // string name;
        // string symbol;
    }

    mapping (address => bool) public relayer;
    mapping (address => bool) public acceptToken;
    mapping (Chain => bool) public acceptChain;
    mapping (bytes32 => address[]) public relayInfo;
    uint256 public confirmRequireNum;
    mapping (Chain => uint256) public fee;
    mapping (address => uint256) public maxAmountPerDay;
    mapping (address => uint256) public maxAmount;
    mapping (address => uint256) public minAmount;
    mapping (address => uint256) public sendTotalAmount;
    mapping (uint256 => CrossTransaction) public sendTotalIndex;
    uint256 public sendIndex;
    mapping (address => uint256) public receiveTotalAmount;
    mapping (uint256 => CrossTransaction) public receiveTotalIndex;
    uint256 public receiveIndex;
    uint256 public timestamp;
    bool public paused;

    modifier onlyRelayer() {
        require(relayer[msg.sender], "Caller is not the relayer");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }
}