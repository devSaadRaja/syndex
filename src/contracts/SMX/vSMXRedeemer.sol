// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IvSMXRedeemer.sol";

/// @title A redemption contract for SMX
/// @dev All vSMX used for redemption is locked within this contract
contract vSMXRedeemer is IvSMXRedeemer {
    /// token to be burned
    address public immutable vToken;
    /// token to be redeemed
    address public immutable token;

    event Redeemed(address redeemer, uint256 redeemedAmount);

    constructor(address _vToken, address _token) {
        vToken = _vToken;
        token = _token;
    }

    /// Allows caller to redeem an equivalent amount of token for vToken
    /// @dev caller must approve this contract to spend vToken
    /// @notice vToken is locked within this contract prior to transfer of token
    function redeem() external override {
        uint256 vTokenBalance = IERC20(vToken).balanceOf(msg.sender);

        /// ensure valid balance
        require(vTokenBalance > 0, "vSMXRedeemer: No balance to redeem");
        require(
            vTokenBalance <= IERC20(token).balanceOf(address(this)),
            "vSMXRedeemer: Insufficient contract balance"
        );

        /// lock vToken in this contract
        require(
            IERC20(vToken).transferFrom(
                msg.sender,
                address(this),
                vTokenBalance
            ),
            "vSMXRedeemer: vToken transfer failed"
        );

        /// transfer token
        require(
            IERC20(token).transfer(msg.sender, vTokenBalance),
            "vSMXRedeemer: token transfer failed"
        );

        emit Redeemed(msg.sender, vTokenBalance);
    }
}
