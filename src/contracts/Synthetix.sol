// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./tax/Taxable.sol";
import "./BaseSynthetix.sol";

import "../interfaces/ITaxable.sol";
import "../interfaces/IRewardEscrow.sol";
import "../interfaces/IRewardEscrowV2.sol";

// import "../interfaces/ISupplySchedule.sol";

contract Synthetix is BaseSynthetix {
    using SafeMath for uint;

    bytes32 public constant CONTRACT_NAME = "Synthetix";

    ITaxable public taxable;

    address public reserveAddr;
    bool public activeTrade = false;
    bool public deploymentSet = false; // make it true once all prerequisites are set

    // ========== ADDRESS RESOLVER CONFIGURATION ==========
    bytes32 private constant CONTRACT_REWARD_ESCROW = "RewardEscrow";

    // bytes32 private constant CONTRACT_SUPPLYSCHEDULE = "SupplySchedule";

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
    {}

    modifier isValidAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    function setDeploy(bool val) external onlyOwner {
        deploymentSet = val;
    }

    function setTrade(bool val) external onlyOwner {
        activeTrade = val;
    }

    function setTaxable(address addr) external onlyOwner {
        taxable = ITaxable(addr);
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
                address[] memory path = new address[](2);
                path[0] = address(proxy);
                path[1] = taxable.rewardAddr();

                uint[] memory amounts = IUniswapV2Router02(taxable.routerAddr())
                    .getAmountsOut(taxable.currentFeeAmount(), path);

                if (amounts[amounts.length - 1] >= taxable.threshold()) {
                    taxable.distributeTax();
                }
            }
        }

        tokenState.setBalanceOf(from, tokenState.balanceOf(from).sub(value));

        emitTransfer(from, to, value);

        return true;
    }

    // ! ----------------------------------------------------

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
        // newAddresses[1] = CONTRACT_SUPPLYSCHEDULE;
        return combineArrays(existingAddresses, newAddresses);
    }

    // ========== VIEWS ==========

    function rewardEscrow() internal view returns (IRewardEscrow) {
        return IRewardEscrow(requireAndGetAddress(CONTRACT_REWARD_ESCROW));
    }

    // function supplySchedule() internal view returns (ISupplySchedule) {
    //     return ISupplySchedule(requireAndGetAddress(CONTRACT_SUPPLYSCHEDULE));
    // }

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
            exchanger().exchange(
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

    // SIP-140 The initiating user of this exchange will receive the proceeds of the exchange
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
        (amountReceived, ) = exchanger().exchange(
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
    ) external onlyOwner isValidAddress(account) {
        totalSupply = totalSupply.add(amount);
        tokenState.setBalanceOf(
            account,
            tokenState.balanceOf(account).add(amount)
        );
        emitTransfer(address(0), account, amount);
    }

    function setReserveAddress(
        address _reserveAddr
    ) external onlyOwner isValidAddress(_reserveAddr) {
        reserveAddr = _reserveAddr;
    }

    function burn() external onlyOwner isValidAddress(reserveAddr) {
        uint256 amount = 100000 ether;

        require(
            tokenState.balanceOf(reserveAddr) >= amount,
            "ERC20: burn amount exceeds balance"
        );

        address spender = _msgSender();
        if (reserveAddr != spender) {
            uint256 currentAllowance = allowance(reserveAddr, spender);
            if (currentAllowance != type(uint256).max) {
                require(
                    currentAllowance >= amount,
                    "ERC20: insufficient allowance"
                );
                approve(spender, currentAllowance.sub(amount));
            }
        }

        totalSupply = totalSupply.sub(amount);
        tokenState.setBalanceOf(
            reserveAddr,
            tokenState.balanceOf(reserveAddr).sub(amount)
        );

        emitTransfer(reserveAddr, address(0), amount);
    }

    // function mint() external override issuanceActive returns (bool) {
    //     require(
    //         address(rewardsDistribution()) != address(0),
    //         "RewardsDistribution not set"
    //     );

    //     ISupplySchedule _supplySchedule = supplySchedule();
    //     IRewardsDistribution _rewardsDistribution = rewardsDistribution();

    //     uint supplyToMint = _supplySchedule.mintableSupply();
    //     require(supplyToMint > 0, "No supply is mintable");

    //     emitTransfer(address(0), address(this), supplyToMint);

    //     // record minting event before mutation to token supply
    //     uint minterReward = _supplySchedule.recordMintEvent(supplyToMint);

    //     // Set minted SNX balance to RewardEscrow's balance
    //     // Minus the minterReward and set balance of minter to add reward
    //     uint amountToDistribute = supplyToMint.sub(minterReward);

    //     // Set the token balance to the RewardsDistribution contract
    //     tokenState.setBalanceOf(
    //         address(_rewardsDistribution),
    //         tokenState.balanceOf(address(_rewardsDistribution)).add(
    //             amountToDistribute
    //         )
    //     );
    //     emitTransfer(
    //         address(this),
    //         address(_rewardsDistribution),
    //         amountToDistribute
    //     );

    //     // Kick off the distribution of rewards
    //     _rewardsDistribution.distributeRewards(amountToDistribute);

    //     // Assign the minters reward.
    //     tokenState.setBalanceOf(
    //         msg.sender,
    //         tokenState.balanceOf(msg.sender).add(minterReward)
    //     );
    //     emitTransfer(address(this), msg.sender, minterReward);

    //     // Increase total supply by minted amount
    //     totalSupply = totalSupply.add(supplyToMint);

    //     return true;
    // }

    /* Once off function for SIP-60 to migrate SNX balances in the RewardEscrow contract
     * To the new RewardEscrowV2 contract
     */
    function migrateEscrowBalanceToRewardEscrowV2() external onlyOwner {
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
