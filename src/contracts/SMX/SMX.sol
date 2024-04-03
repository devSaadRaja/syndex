// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC20.sol";
import "./Taxable.sol";
import "./Blacklist.sol";

import "./interfaces/ISupplySchedule.sol";

contract SMX is Ownable, ERC20, Taxable, Blacklist {
    /// @notice defines inflationary supply schedule,
    /// according to which the SMX inflationary supply is released
    ISupplySchedule public supplySchedule;

    address public reserveAddr;
    bool public activeTrade = false;
    bool public deploymentSet = false; // make it true once all prerequisites are set

    modifier onlySupplySchedule() {
        require(
            msg.sender == address(supplySchedule),
            "Kwenta: Only SupplySchedule can perform this action"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _owner,
        uint256 _initialSupply
    ) ERC20(name, symbol) Ownable(_owner) {
        _mint(_owner, _initialSupply);
    }

    // // Mints inflationary supply
    // function mint(
    //     address account,
    //     uint256 amount
    // ) external override onlySupplySchedule {
    //     _mint(account, amount);
    // }

    function burn() external onlyOwner {
        require(reserveAddr != address(0), "Invalid address");
        uint256 amount = 100000 ether;

        _burn(reserveAddr, amount);
    }

    function setSupplySchedule(address _supplySchedule) external onlyOwner {
        require(_supplySchedule != address(0), "Kwenta: Invalid Address");
        supplySchedule = ISupplySchedule(_supplySchedule);
    }

    function setDeploy(bool val) external onlyOwner {
        deploymentSet = val;
    }

    function setTrade(bool val) external onlyOwner {
        activeTrade = val;
    }

    function setReserveAddress(address _reserveAddr) external onlyOwner {
        require(_reserveAddr != address(0), "Invalid address");
        reserveAddr = _reserveAddr;
    }

    function transfer(
        address to,
        uint256 value
    )
        public
        override
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override notBlacklisted(from) notBlacklisted(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function _transfer(address from, address to, uint value) internal override {
        require(
            to != address(0) && to != address(this),
            "Cannot transfer to this address"
        );

        if (
            from != owner() &&
            (pool[from] || pool[to]) &&
            (!isExcludedFromFee[from] && !isExcludedFromFee[to])
        ) {
            require(activeTrade, "Trade not active!");

            uint256 taxAmount = pool[from]
                ? getTaxAmount(value, true)
                : getTaxAmount(value, false);
            uint256 transferAmount = calculateTransferAmount(value, taxAmount);

            currentFeeAmount += taxAmount;
            _balances[address(this)] += taxAmount;

            _balances[to] += transferAmount;
        } else {
            _balances[to] += value;

            if (
                deploymentSet &&
                currentFeeAmount > 0 &&
                (!isExcludedFromFee[from] && !isExcludedFromFee[to])
            ) {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = rewardAddr;

                uint[] memory amounts = IUniswapV2Router02(routerAddr)
                    .getAmountsOut(currentFeeAmount, path);

                if (amounts[amounts.length - 1] >= threshold) _distribute();
            }
        }

        _balances[from] -= value;

        emit Transfer(from, to, value);
    }
}
