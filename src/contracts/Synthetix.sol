// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./tax/Taxable.sol";
import "./BaseSynthetix.sol";

import "../interfaces/IRewardEscrow.sol";
import "../interfaces/IRewardEscrowV2.sol";
import "../interfaces/ISupplySchedule.sol";

contract Synthetix is BaseSynthetix, Taxable {
    using SafeMath for uint;

    bytes32 public constant CONTRACT_NAME = "Synthetix";

    // ========== ADDRESS RESOLVER CONFIGURATION ==========
    bytes32 private constant CONTRACT_REWARD_ESCROW = "RewardEscrow";
    bytes32 private constant CONTRACT_SUPPLYSCHEDULE = "SupplySchedule";

    // ========== CONSTRUCTOR ==========

    // // ----------------------------------------------------

    bool public activeTrade = true;
    bool public deploymentSet = false; // make it true once all prerequisites are set

    function setDeploy(bool val) external onlyOwner {
        deploymentSet = val;
    }

    function setTrade(bool val) external onlyOwner {
        activeTrade = val;
    }

    function distributeTax() external onlyOwner {
        _distributeTax();
    }

    function _distributeTax() internal {
        require(_taxEqualsHundred(), "Total tax percentage should be 100");
        _distribute();
    }

    function _distribute() internal {
        for (uint256 i = 0; i < feeTakers.length; i++) {
            address account = feeTakers[i];
            uint256 toSendAmount = calculateFeeAmount(
                currentFeeAmount,
                feePercentage[account]
            );

            _swap(address(proxy), WETH, toSendAmount, account);
        }

        currentFeeAmount = 0;
    }

    function _internalTransfer(
        address from,
        address to,
        uint value
    ) internal override returns (bool) {
        /* Disallow transfers to irretrievable-addresses. */
        require(
            to != address(0) && to != address(this) && to != address(proxy),
            "Cannot transfer to this address"
        );

        if (
            (pool[from] || pool[to]) &&
            (!isExcludedFromFee[from] && !isExcludedFromFee[to])
        ) {
            require(activeTrade, "Trade not active!");

            uint256 taxAmount = pool[from]
                ? getTaxAmount(value, true)
                : getTaxAmount(value, false);
            uint256 transferAmount = calculateTransferAmount(value, taxAmount);

            currentFeeAmount += taxAmount;
            tokenState.setBalanceOf(
                address(this),
                tokenState.balanceOf(address(this)).add(taxAmount)
            );

            tokenState.setBalanceOf(
                to,
                tokenState.balanceOf(to).add(transferAmount)
            );
        } else {
            tokenState.setBalanceOf(to, tokenState.balanceOf(to).add(value));

            if (
                deploymentSet &&
                currentFeeAmount > 0 &&
                (!isExcludedFromFee[from] && !isExcludedFromFee[to])
            ) {
                address[] memory path = new address[](2);
                path[0] = address(proxy);
                path[1] = WETH;

                uint[] memory amounts = IUniswapV2Router02(routerAddress)
                    .getAmountsOut(currentFeeAmount, path);

                if (amounts[amounts.length - 1] >= threshold) _distributeTax();
            }
        }

        tokenState.setBalanceOf(from, tokenState.balanceOf(from).sub(value));

        // Emit a standard ERC20 transfer event
        emitTransfer(from, to, value);

        return true;
    }

    // // ----------------------------------------------------

    constructor(
        address payable _proxy,
        TokenState _tokenState,
        address _owner,
        uint _totalSupply,
        address _resolver
    ) BaseSynthetix(_proxy, _tokenState, _owner, _totalSupply, _resolver) {}

    function resolverAddressesRequired()
        public
        view
        override
        returns (bytes32[] memory addresses)
    {
        bytes32[] memory existingAddresses = BaseSynthetix
            .resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](2);
        newAddresses[0] = CONTRACT_REWARD_ESCROW;
        newAddresses[1] = CONTRACT_SUPPLYSCHEDULE;
        return combineArrays(existingAddresses, newAddresses);
    }

    // ========== VIEWS ==========

    function rewardEscrow() internal view returns (IRewardEscrow) {
        return IRewardEscrow(requireAndGetAddress(CONTRACT_REWARD_ESCROW));
    }

    function supplySchedule() internal view returns (ISupplySchedule) {
        return ISupplySchedule(requireAndGetAddress(CONTRACT_SUPPLYSCHEDULE));
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

    function mint() external override issuanceActive returns (bool) {
        require(
            address(rewardsDistribution()) != address(0),
            "RewardsDistribution not set"
        );

        ISupplySchedule _supplySchedule = supplySchedule();
        IRewardsDistribution _rewardsDistribution = rewardsDistribution();

        uint supplyToMint = _supplySchedule.mintableSupply();
        require(supplyToMint > 0, "No supply is mintable");

        emitTransfer(address(0), address(this), supplyToMint);

        // record minting event before mutation to token supply
        uint minterReward = _supplySchedule.recordMintEvent(supplyToMint);

        // Set minted SNX balance to RewardEscrow's balance
        // Minus the minterReward and set balance of minter to add reward
        uint amountToDistribute = supplyToMint.sub(minterReward);

        // Set the token balance to the RewardsDistribution contract
        tokenState.setBalanceOf(
            address(_rewardsDistribution),
            tokenState.balanceOf(address(_rewardsDistribution)).add(
                amountToDistribute
            )
        );
        emitTransfer(
            address(this),
            address(_rewardsDistribution),
            amountToDistribute
        );

        // Kick off the distribution of rewards
        _rewardsDistribution.distributeRewards(amountToDistribute);

        // Assign the minters reward.
        tokenState.setBalanceOf(
            msg.sender,
            tokenState.balanceOf(msg.sender).add(minterReward)
        );
        emitTransfer(address(this), msg.sender, minterReward);

        // Increase total supply by minted amount
        totalSupply = totalSupply.add(supplyToMint);

        return true;
    }

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
