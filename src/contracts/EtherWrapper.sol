// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./MixinSystemSettings.sol";

import "../interfaces/IWETH.sol";
import "../interfaces/ISynth.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IIssuer.sol";
import "../interfaces/IFeePool.sol";
import "../interfaces/IEtherWrapper.sol";
import "../interfaces/IExchangeRates.sol";
import "../interfaces/IAddressResolver.sol";

import "../libraries/SafeDecimalMath.sol";

contract EtherWrapper is Ownable, Pausable, MixinSystemSettings, IEtherWrapper {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* ========== CONSTANTS ============== */

    /* ========== ENCODED NAMES ========== */

    bytes32 internal constant cfUSD = "cfUSD";
    bytes32 internal constant cfETH = "cfETH";
    bytes32 internal constant ETH = "ETH";
    bytes32 internal constant SFCX = "SFCX";

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */
    bytes32 private constant CONTRACT_SYNTHSETH = "SynthcfETH";
    bytes32 private constant CONTRACT_SYNTHSUSD = "SynthcfUSD";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";

    // ========== STATE VARIABLES ==========
    IWETH internal _weth;

    uint public cfETHIssued = 0;
    uint public cfUSDIssued = 0;
    uint public feesEscrowed = 0;

    constructor(
        address _owner,
        address _resolver,
        address payable _WETH
    ) Ownable(_owner) Pausable() MixinSystemSettings(_resolver) {
        _weth = IWETH(_WETH);
    }

    /* ========== VIEWS ========== */
    function resolverAddressesRequired()
        public
        view
        override
        returns (bytes32[] memory addresses)
    {
        bytes32[] memory existingAddresses = MixinSystemSettings
            .resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](5);
        newAddresses[0] = CONTRACT_SYNTHSETH;
        newAddresses[1] = CONTRACT_SYNTHSUSD;
        newAddresses[2] = CONTRACT_EXRATES;
        newAddresses[3] = CONTRACT_ISSUER;
        newAddresses[4] = CONTRACT_FEEPOOL;
        addresses = combineArrays(existingAddresses, newAddresses);
        return addresses;
    }

    /* ========== INTERNAL VIEWS ========== */
    function synthcfUSD() internal view returns (ISynth) {
        return ISynth(requireAndGetAddress(CONTRACT_SYNTHSUSD));
    }

    function synthcfETH() internal view returns (ISynth) {
        return ISynth(requireAndGetAddress(CONTRACT_SYNTHSETH));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // ========== VIEWS ==========

    function capacity() public view returns (uint _capacity) {
        // capacity = max(maxETH - balance, 0)
        uint balance = getReserves();
        if (balance >= maxETH()) {
            return 0;
        }
        return maxETH().sub(balance);
    }

    function getReserves() public view returns (uint) {
        return _weth.balanceOf(address(this));
    }

    function totalIssuedSynths() public view returns (uint) {
        // This contract issues two different synths:
        // 1. cfETH
        // 2. cfUSD
        //
        // The cfETH is always backed 1:1 with WETH.
        // The cfUSD fees are backed by cfETH that is withheld during minting and burning.
        return
            exchangeRates().effectiveValue(cfETH, cfETHIssued, cfUSD).add(
                cfUSDIssued
            );
    }

    function calculateMintFee(uint amount) public view returns (uint) {
        return amount.multiplyDecimalRound(mintFeeRate());
    }

    function calculateBurnFee(uint amount) public view returns (uint) {
        return amount.multiplyDecimalRound(burnFeeRate());
    }

    function maxETH() public view returns (uint256) {
        return getEtherWrapperMaxETH();
    }

    function mintFeeRate() public view returns (uint256) {
        return getEtherWrapperMintFeeRate();
    }

    function burnFeeRate() public view returns (uint256) {
        return getEtherWrapperBurnFeeRate();
    }

    function weth() public view returns (IWETH) {
        return _weth;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Transfers `amountIn` WETH to mint `amountIn - fees` cfETH.
    // `amountIn` is inclusive of fees, calculable via `calculateMintFee`.
    function mint(uint amountIn) external whenNotPaused {
        require(
            amountIn <= _weth.allowance(msg.sender, address(this)),
            "Allowance not high enough"
        );
        require(amountIn <= _weth.balanceOf(msg.sender), "Balance is too low");

        uint currentCapacity = capacity();
        require(currentCapacity > 0, "Contract has no spare capacity to mint");

        if (amountIn < currentCapacity) {
            _mint(amountIn);
        } else {
            _mint(currentCapacity);
        }
    }

    // Burns `amountIn` cfETH for `amountIn - fees` WETH.
    // `amountIn` is inclusive of fees, calculable via `calculateBurnFee`.
    function burn(uint amountIn) external whenNotPaused {
        uint reserves = getReserves();
        require(
            reserves > 0,
            "Contract cannot burn cfETH for WETH, WETH balance is zero"
        );

        // principal = [amountIn / (1 + burnFeeRate)]
        uint principal = amountIn.divideDecimalRound(
            SafeDecimalMath.unit().add(burnFeeRate())
        );

        if (principal < reserves) {
            _burn(principal, amountIn);
        } else {
            _burn(reserves, reserves.add(calculateBurnFee(reserves)));
        }
    }

    function distributeFees() external {
        // Normalize fee to cfUSD
        require(
            !exchangeRates().rateIsInvalid(cfETH),
            "Currency rate is invalid"
        );
        uint amountSUSD = exchangeRates().effectiveValue(
            cfETH,
            feesEscrowed,
            cfUSD
        );

        // Burn cfETH.
        synthcfETH().burn(address(this), feesEscrowed);
        // Pay down as much cfETH debt as we burn. Any other debt is taken on by the stakers.
        cfETHIssued = cfETHIssued < feesEscrowed
            ? 0
            : cfETHIssued.sub(feesEscrowed);

        // Issue cfUSD to the fee pool
        issuer().synths(cfUSD).issue(feePool().FEE_ADDRESS(), amountSUSD);
        cfUSDIssued = cfUSDIssued.add(amountSUSD);

        // Tell the fee pool about this
        feePool().recordFeePaid(amountSUSD);

        feesEscrowed = 0;
    }

    // ========== RESTRICTED ==========

    /**
     * @notice Fallback function
     */
    fallback() external payable {
        revert("Fallback disabled, use mint()");
    }

    receive() external payable {}

    /* ========== INTERNAL FUNCTIONS ========== */

    function _mint(uint amountIn) internal {
        // Calculate minting fee.
        uint feeAmountEth = calculateMintFee(amountIn);
        uint principal = amountIn.sub(feeAmountEth);

        // Transfer WETH from user.
        _weth.transferFrom(msg.sender, address(this), amountIn);

        // Mint `amountIn - fees` cfETH to user.
        synthcfETH().issue(msg.sender, principal);

        // Escrow fee.
        synthcfETH().issue(address(this), feeAmountEth);
        feesEscrowed = feesEscrowed.add(feeAmountEth);

        // Add cfETH debt.
        cfETHIssued = cfETHIssued.add(amountIn);

        emit Minted(msg.sender, principal, feeAmountEth, amountIn);
    }

    function _burn(uint principal, uint amountIn) internal {
        // for burn, amount is inclusive of the fee.
        uint feeAmountEth = amountIn.sub(principal);

        require(
            amountIn <=
                IERC20(address(synthcfETH())).allowance(
                    msg.sender,
                    address(this)
                ),
            "Allowance not high enough"
        );
        require(
            amountIn <= IERC20(address(synthcfETH())).balanceOf(msg.sender),
            "Balance is too low"
        );

        // Burn `amountIn` cfETH from user.
        synthcfETH().burn(msg.sender, amountIn);
        // cfETH debt is repaid by burning.
        cfETHIssued = cfETHIssued < principal ? 0 : cfETHIssued.sub(principal);

        // We use burn/issue instead of burning the principal and transferring the fee.
        // This saves an approval and is cheaper.
        // Escrow fee.
        synthcfETH().issue(address(this), feeAmountEth);
        // We don't update cfETHIssued, as only the principal was subtracted earlier.
        feesEscrowed = feesEscrowed.add(feeAmountEth);

        // Transfer `amount - fees` WETH to user.
        _weth.transfer(msg.sender, principal);

        emit Burned(msg.sender, principal, feeAmountEth, amountIn);
    }

    /* ========== EVENTS ========== */
    event Minted(
        address indexed account,
        uint principal,
        uint fee,
        uint amountIn
    );
    event Burned(
        address indexed account,
        uint principal,
        uint fee,
        uint amountIn
    );
}
