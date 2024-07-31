// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/ISynth.sol";
import "../interfaces/ISynDex.sol";
import "../interfaces/IExchangeRates.sol";
import "../interfaces/IAddressResolver.sol";

contract SynthUtil {
    IAddressResolver public addressResolver;

    bytes32 internal constant CONTRACT_SYNDEX = "SynDex";
    bytes32 internal constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 internal constant CFUSD = "cfUSD";

    constructor(address resolver) {
        addressResolver = IAddressResolver(resolver);
    }

    function _syndex() internal view returns (ISynDex) {
        return
            ISynDex(
                addressResolver.requireAndGetAddress(
                    CONTRACT_SYNDEX,
                    "Missing SynDex address"
                )
            );
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return
            IExchangeRates(
                addressResolver.requireAndGetAddress(
                    CONTRACT_EXRATES,
                    "Missing ExchangeRates address"
                )
            );
    }

    function totalSynthsInKey(
        address account,
        bytes32 currencyKey
    ) external view returns (uint total) {
        ISynDex syndex = _syndex();
        IExchangeRates exchangeRates = _exchangeRates();
        uint numSynths = syndex.availableSynthCount();
        for (uint i = 0; i < numSynths; i++) {
            ISynth synth = syndex.availableSynths(i);
            total += exchangeRates.effectiveValue(
                synth.currencyKey(),
                IERC20(address(synth)).balanceOf(account),
                currencyKey
            );
        }
        return total;
    }

    function synthsBalances(
        address account
    ) external view returns (bytes32[] memory, uint[] memory, uint[] memory) {
        ISynDex syndex = _syndex();
        IExchangeRates exchangeRates = _exchangeRates();
        uint numSynths = syndex.availableSynthCount();
        bytes32[] memory currencyKeys = new bytes32[](numSynths);
        uint[] memory balances = new uint[](numSynths);
        uint[] memory cfUSDBalances = new uint[](numSynths);
        for (uint i = 0; i < numSynths; i++) {
            ISynth synth = syndex.availableSynths(i);
            currencyKeys[i] = synth.currencyKey();
            balances[i] = IERC20(address(synth)).balanceOf(account);
            cfUSDBalances[i] = exchangeRates.effectiveValue(
                currencyKeys[i],
                balances[i],
                CFUSD
            );
        }
        return (currencyKeys, balances, cfUSDBalances);
    }

    function synthsRates()
        external
        view
        returns (bytes32[] memory, uint[] memory)
    {
        bytes32[] memory currencyKeys = _syndex().availableCurrencyKeys();
        return (
            currencyKeys,
            _exchangeRates().ratesForCurrencies(currencyKeys)
        );
    }

    function synthsTotalSupplies()
        external
        view
        returns (bytes32[] memory, uint256[] memory, uint256[] memory)
    {
        ISynDex syndex = _syndex();
        IExchangeRates exchangeRates = _exchangeRates();

        uint256 numSynths = syndex.availableSynthCount();
        bytes32[] memory currencyKeys = new bytes32[](numSynths);
        uint256[] memory balances = new uint256[](numSynths);
        uint256[] memory cfUSDBalances = new uint256[](numSynths);
        for (uint256 i = 0; i < numSynths; i++) {
            ISynth synth = syndex.availableSynths(i);
            currencyKeys[i] = synth.currencyKey();
            balances[i] = IERC20(address(synth)).totalSupply();
            cfUSDBalances[i] = exchangeRates.effectiveValue(
                currencyKeys[i],
                balances[i],
                CFUSD
            );
        }
        return (currencyKeys, balances, cfUSDBalances);
    }
}
