// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./Wrapper.sol";
import "./MixinResolver.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/IFeePool.sol";
import "../interfaces/IWrapperFactory.sol";
import "../interfaces/IFlexibleStorage.sol";

contract WrapperFactory is Ownable, MixinResolver, IWrapperFactory {
    bytes32 public constant CONTRACT_NAME = "WrapperFactory";

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";
    bytes32 internal constant CONTRACT_SYNTH_SUSD = "SynthsUSD";
    bytes32 internal constant CONTRACT_FEEPOOL = "FeePool";

    uint internal constant WRAPPER_VERSION = 1;

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _owner,
        address _resolver
    ) Ownable(_owner) MixinResolver(_resolver) {}

    function resolverAddressesRequired()
        public
        view
        override
        returns (bytes32[] memory addresses)
    {
        addresses = new bytes32[](3);
        addresses[0] = CONTRACT_SYNTH_SUSD;
        addresses[1] = CONTRACT_FLEXIBLESTORAGE;
        addresses[2] = CONTRACT_FEEPOOL;
    }

    /* ========== INTERNAL VIEWS ========== */
    function synthsUSD() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTH_SUSD));
    }

    function flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    // ========== VIEWS ==========
    // Returns the version of a wrapper created by this wrapper factory
    // Used by MultiCollateralSynth to know if it should trust the wrapper contract
    function isWrapper(address possibleWrapper) external view returns (bool) {
        return
            flexibleStorage().getUIntValue(
                CONTRACT_NAME,
                bytes32(uint(uint160(possibleWrapper)))
            ) > 0;
    }

    function feesEscrowed() public view returns (uint) {
        return synthsUSD().balanceOf(address(this));
    }

    // ========== RESTRICTED ==========

    /**
     * @notice Fallback function
     */
    fallback() external payable {
        revert("Contract is not payable");
    }

    receive() external payable {}

    /* ========== MUTATIVE FUNCTIONS ========== */
    function createWrapper(
        IERC20 token,
        bytes32 currencyKey,
        bytes32 synthContractName
    ) external onlyOwner returns (address) {
        // Create the wrapper instance
        Wrapper wrapper = new Wrapper(
            owner(),
            address(resolver),
            token,
            currencyKey,
            synthContractName
        );

        // Rebuild caches immediately since it will almost certainly need to be done
        wrapper.refreshCache();

        // Register it so that MultiCollateralSynth knows to trust it
        flexibleStorage().setUIntValue(
            CONTRACT_NAME,
            bytes32(uint(uint160(address(wrapper)))),
            WRAPPER_VERSION
        );

        emit WrapperCreated(address(token), currencyKey, address(wrapper));

        return address(wrapper);
    }

    function distributeFees() external {
        // Normalize fee to sUSD
        uint amountSUSD = feesEscrowed();

        if (amountSUSD > 0) {
            // Transfer sUSD to the fee pool
            bool success = synthsUSD().transfer(
                feePool().FEE_ADDRESS(),
                amountSUSD
            );
            require(success, "Transfer did not succeed");
        }
    }

    event WrapperCreated(
        address indexed token,
        bytes32 indexed currencyKey,
        address wrapperAddress
    );
}
