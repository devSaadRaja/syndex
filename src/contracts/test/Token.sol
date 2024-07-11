// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        address _initialOwner,
        uint _amount
    ) ERC20(_name, _symbol) {
        _mint(_initialOwner, _amount);
    }
}
