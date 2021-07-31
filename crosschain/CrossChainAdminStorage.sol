// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "../openzeppelin-contracts/contracts/access/Ownable.sol";

contract CrossChainAdminStorage is Ownable{

    address public admin;

    address public implementation;

    modifier onlyAdmin() {
        require(admin == msg.sender, "Caller is not the admin");
        _;
    }
}
