// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./BaseSynthetix.sol";

import "../interfaces/ITaxable.sol";
import "../interfaces/IRewardEscrow.sol";
import "../interfaces/IRewardEscrowV2.sol";

contract Synthetix is AccessControl, BaseSynthetix {
    using SafeMath for uint;

    bytes32 public constant CONTRACT_NAME = "Synthetix";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    ITaxable public taxable;
    bool public activeTrade = false;
    bool public deploymentSet = false; // make it true once all prerequisites are set

    address public reserveAddr;
    uint256 burnAmount = 100000 ether;

    // ========== ADDRESS RESOLVER CONFIGURATION ==========
    bytes32 private constant CONTRACT_REWARD_ESCROW = "RewardEscrow";

    modifier isValidAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    // ========== CONSTRUCTOR ==========

    constructor(
        address payable _proxy,
        address _tokenState,
        address _owner,
        uint _totalSupply,
        address _resolver
    )
        BaseSynthetix(
            _proxy,
            TokenState(_tokenState),
            _owner,
            _totalSupply,
            _resolver
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MINTER_ROLE, _owner);
        _grantRole(BURNER_ROLE, _owner);
    }

    function setDeploy(bool val) external onlyRole(DEFAULT_ADMIN_ROLE) {
        deploymentSet = val;
    }

    function setTrade(bool val) external onlyRole(DEFAULT_ADMIN_ROLE) {
        activeTrade = val;
    }

    function setTaxable(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        taxable = ITaxable(addr);
    }

    function setReserveAddress(
        address _reserveAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) isValidAddress(_reserveAddr) {
        reserveAddr = _reserveAddr;
    }

    function setBurnAmount(
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        burnAmount = _amount;
    }

    function resolverAddressesRequired()
        public
        view
        override
        returns (bytes32[] memory addresses)
    {
        bytes32[] memory existingAddresses = BaseSynthetix
            .resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_REWARD_ESCROW;
        return combineArrays(existingAddresses, newAddresses);
    }

    // ========== VIEWS ==========

    function rewardEscrow() internal view returns (IRewardEscrow) {
        return IRewardEscrow(requireAndGetAddress(CONTRACT_REWARD_ESCROW));
    }

    // ========== OVERRIDDEN FUNCTIONS ==========

    function exchangeWithVirtual(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode
    )
        external
        override
        exchangeActive(sourceCurrencyKey, destinationCurrencyKey)
        optionalProxy
        returns (uint amountReceived, IVirtualSynth vSynth)
    {
        return
            exchanger().executeExchange(
                messageSender,
                messageSender,
                sourceCurrencyKey,
                sourceAmount,
                destinationCurrencyKey,
                messageSender,
                true,
                messageSender,
                trackingCode
            );
    }

    // SIP-140 The initiating user of this executeExchange will receive the proceeds of the executeExchange
    // Note: this function may have unintended consequences if not understood correctly. Please
    // read SIP-140 for more information on the use-case
    function exchangeWithTrackingForInitiator(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    )
        external
        override
        exchangeActive(sourceCurrencyKey, destinationCurrencyKey)
        optionalProxy
        returns (uint amountReceived)
    {
        (amountReceived, ) = exchanger().executeExchange(
            messageSender,
            messageSender,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            // solhint-disable avoid-tx-origin
            tx.origin,
            false,
            rewardAddress,
            trackingCode
        );
    }

    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint minAmount
    )
        external
        override
        exchangeActive(sourceCurrencyKey, destinationCurrencyKey)
        optionalProxy
        returns (uint amountReceived)
    {
        return
            exchanger().exchangeAtomically(
                messageSender,
                sourceCurrencyKey,
                sourceAmount,
                destinationCurrencyKey,
                messageSender,
                trackingCode,
                minAmount
            );
    }

    function settle(
        bytes32 currencyKey
    )
        external
        override
        optionalProxy
        returns (uint reclaimed, uint refunded, uint numEntriesSettled)
    {
        return exchanger().settle(messageSender, currencyKey);
    }

    function mint(
        address account,
        uint amount
    ) external onlyRole(MINTER_ROLE) isValidAddress(account) {
        totalSupply = totalSupply.add(amount);
        tokenState.setBalanceOf(
            account,
            tokenState.balanceOf(account).add(amount)
        );
        emitTransfer(address(0), account, amount);
    }

    function burn() external onlyRole(BURNER_ROLE) isValidAddress(reserveAddr) {
        require(
            tokenState.balanceOf(reserveAddr) >= burnAmount,
            "ERC20: burn amount exceeds balance"
        );

        address spender = _msgSender();

        if (reserveAddr != spender) {
            uint256 currentAllowance = allowance(reserveAddr, spender);
            if (currentAllowance != type(uint256).max) {
                require(
                    currentAllowance >= burnAmount,
                    "ERC20: insufficient allowance"
                );
                approve(spender, currentAllowance.sub(burnAmount));
            }
        }

        totalSupply = totalSupply.sub(burnAmount);

        tokenState.setBalanceOf(
            reserveAddr,
            tokenState.balanceOf(reserveAddr).sub(burnAmount)
        );

        emitTransfer(reserveAddr, address(0), burnAmount);
    }

    /* Once off function for SIP-60 to migrate SCFX balances in the RewardEscrow contract
     * To the new RewardEscrowV2 contract
     */
    function migrateEscrowBalanceToRewardEscrowV2()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Record balanceOf(RewardEscrow) contract
        uint rewardEscrowBalance = tokenState.balanceOf(
            address(rewardEscrow())
        );

        // transfer all of RewardEscrow's balance to RewardEscrowV2
        // _internalTransfer emits the transfer event
        _internalTransfer(
            address(rewardEscrow()),
            address(rewardEscrowV2()),
            rewardEscrowBalance
        );
    }

    function _internalTransfer(
        address from,
        address to,
        uint value
    ) internal override returns (bool) {
        require(
            to != address(0) && to != address(this) && to != address(proxy),
            "Cannot transfer to this address"
        );

        if (
            from != owner() &&
            (taxable.pool(from) || taxable.pool(to)) &&
            (!taxable.isExcludedFromFee(from) && !taxable.isExcludedFromFee(to))
        ) {
            require(activeTrade, "Trade not active!");

            uint256 taxAmount = taxable.pool(from)
                ? taxable.getTaxAmount(value, true)
                : taxable.getTaxAmount(value, false);
            uint256 transferAmount = taxable.calculateTransferAmount(
                value,
                taxAmount
            );

            taxable.addToCurrentFeeAmount(taxAmount);

            tokenState.setBalanceOf(
                address(taxable),
                tokenState.balanceOf(address(taxable)).add(taxAmount)
            );
            tokenState.setBalanceOf(
                to,
                tokenState.balanceOf(to).add(transferAmount)
            );
        } else {
            tokenState.setBalanceOf(to, tokenState.balanceOf(to).add(value));

            if (
                deploymentSet &&
                taxable.currentFeeAmount() > 0 &&
                (!taxable.isExcludedFromFee(from) &&
                    !taxable.isExcludedFromFee(to))
            ) {
                taxable.distribute();
            }
        }

        tokenState.setBalanceOf(from, tokenState.balanceOf(from).sub(value));

        emitTransfer(from, to, value);

        return true;
    }

    // ========== EVENTS ==========

    event AtomicSynthExchange(
        address indexed account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    );
    bytes32 internal constant ATOMIC_SYNTH_EXCHANGE_SIG =
        keccak256(
            "AtomicSynthExchange(address,bytes32,uint256,bytes32,uint256,address)"
        );

    function emitAtomicSynthExchange(
        address account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    ) external onlyExchanger {
        proxy._emit(
            abi.encode(
                fromCurrencyKey,
                fromAmount,
                toCurrencyKey,
                toAmount,
                toAddress
            ),
            2,
            ATOMIC_SYNTH_EXCHANGE_SIG,
            addressToBytes32(account),
            0,
            0
        );
    }
}
