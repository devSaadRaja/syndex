// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./BaseSynthetix.sol";

import "../interfaces/IRewardEscrow.sol";
import "../interfaces/IRewardEscrowV2.sol";

// import "../interfaces/ISupplySchedule.sol";

contract Synthetix is AccessControl, BaseSynthetix {
    using SafeMath for uint;

    bytes32 public constant CONTRACT_NAME = "Synthetix";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address public reserveAddr;
    uint256 burnAmount = 100000 ether;

    // ========== ADDRESS RESOLVER CONFIGURATION ==========
    bytes32 private constant CONTRACT_REWARD_ESCROW = "RewardEscrow";

    // bytes32 private constant CONTRACT_SUPPLYSCHEDULE = "SupplySchedule";

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

        tokenState.setBalanceOf(_owner, _totalSupply);
    }

    function setReserveAddress(
        address _reserveAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) isValidAddress(_reserveAddr) {
        reserveAddr = _reserveAddr;
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
