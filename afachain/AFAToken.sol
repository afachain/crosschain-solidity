// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "../openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title AFA ERC20 AFAToken
 *
 * @dev Implementation of the interest bearing token for the DLP protocol.
 * @author AFA-Network
 */
contract AFAToken is ERC20, Ownable {

    struct Transaction {
        //address from;
        address to;
        uint256 value;
        //uint256 createTime;
        uint256 chain;
        //address token;
        // string name;
        // string symbol;
    }
    
    mapping(uint256 => Transaction) public TransactionRecord;

    /**
    * @dev emitted after the redeem action
    * @param _from the address performing the redeem
    * @param _value the amount to be redeemed
    * @param _fromIndex the last index of the user
    **/
    event Redeem(
        address indexed _from,
        uint256 _value,
        uint256 _fromIndex
    );

    /**
    * @dev emitted after the mint action
    * @param _to the address performing the mint
    * @param _value the amount to be minted
    * @param _Index the index of the cross tranaction
    * @param _chain the source chain code
    **/
    event MintOnDeposit(
        address indexed _to,
        uint256 _value,
        uint256 _Index,
        uint256 _chain
    );

    // /**
    // * @dev emitted during the liquidation action, when the liquidator reclaims the underlying
    // * asset
    // * @param _from the address from which the tokens are being burned
    // * @param _value the amount to be burned
    // * @param _fromIndex the last index of the user
    // **/
    // event BurnOnLiquidation(
    //     address indexed _from,
    //     uint256 _value,
    //     uint256 _fromIndex
    // );

    modifier whenTransferAllowed(address _from, uint256 _amount) {
        require(isTransferAllowed(_from, _amount), "Transfer cannot be allowed.");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
    }


    /**
    * @dev redeems AFAToken for the underlying asset
    * @param _amount the amount being redeemed
    **/
    function redeem(uint256 _amount) external payable {

        // burns tokens equivalent to the amount requested
        //_burn(msg.sender, _amount);


        emit Redeem(msg.sender, _amount, 0);
    }

    /**
     * @dev mints token in the event of users depositing
     * @param _to the address receiving the minted tokens
     * @param _amount the amount of tokens to mint
     * @param _index the index of the cross tranaction
     * @param _chain the source chain code
     */
    function mintOnDeposit(address _to, uint256 _amount, uint256 _index, uint256 _chain) external {
        require(_to != address(0), "_to should not be address(0)");
        require(TransactionRecord[_index].to == address(0), "_index already exists");
        // TODO: to get validators and vote the mint
        TransactionRecord[_index] = Transaction(_to, _amount, _chain);
        //mint an equivalent amount of tokens to cover the new deposit
        _mint(_to, _amount);

        emit MintOnDeposit(_to, _amount, _index, _chain);
    }


    /**
     * @dev Used to validate transfers before actually executing them.
     * @param _user address of the user to check
     * @param _amount the amount to check
     * @return true if the _user can transfer _amount, false otherwise
     **/
    function isTransferAllowed(address _user, uint256 _amount) public view returns (bool) {
        return true;
    }
}
