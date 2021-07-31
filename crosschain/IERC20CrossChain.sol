// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "../openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IERC20CrossChain is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}
