// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Blacklist is Ownable {
    mapping(address => bool) public blacklist;

    function updateBlacklist(
        address _account,
        bool _isBlacklisted
    ) external onlyOwner {
        blacklist[_account] = _isBlacklisted;
        emit BlacklistUpdated(_account, _isBlacklisted);
    }

    modifier notBlacklisted(address account) {
        require(!blacklist[account], "Address is blacklisted");
        _;
    }

    event BlacklistUpdated(address indexed account, bool isBlacklisted);
}
