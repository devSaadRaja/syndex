// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

abstract contract Taxable is Ownable {
    // ==================== STRUCTURE ==================== //

    uint256 public buyFee = 2; // 2%
    uint256 public sellFee = 2; // 2%
    uint256 public threshold = 0.1 * 1e18; // in WETH

    uint256 public currentTaxAmount = 0;

    mapping(address => bool) public taxExempts;
    mapping(address => uint256) public taxPercentages;
    address[] taxReceiverList;

    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // mainnet address
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet address

    mapping(address => bool) public pool;
    address[] pools;

    // ==================== EVENTS ==================== //

    event AddPool(address poolAddress);
    event RemovePool(address poolAddress);
    event UpdateFee(uint256 oldPercentage, uint256 newPercentage);
    event AddTaxReceiver(address receiver, uint256 percentage);
    event RemoveTaxReceiver(address receiver);
    event UpdateReceiverTax(
        address receiver,
        uint256 oldPercentage,
        uint256 newPercentage
    );

    // ==================== MODIFIERS ==================== //

    modifier isValidAddress(address account) {
        require(account != address(0), "Invalid address");
        _;
    }

    // ==================== FUNCTIONS ==================== //

    function getAllPools() external view returns (address[] memory) {
        return pools;
    }

    function getAllTaxReceivers() external view returns (address[] memory) {
        return taxReceiverList;
    }

    function addPool(address poolAddress) external onlyOwner {
        require(poolAddress != address(0), "Invalid Pool address");
        require(!pool[poolAddress], "Pool already exists");
        pool[poolAddress] = true;
        pools.push(poolAddress);

        emit AddPool(poolAddress);
    }

    function removePool(uint _index) external onlyOwner {
        require(_index < pools.length);
        emit RemovePool(pools[_index]);
        pool[pools[_index]] = false;
        pools[_index] = pools[pools.length - 1];
        pools.pop();
    }

    function addTaxReceiver(
        address _receiver,
        uint256 _percentage
    ) external onlyOwner {
        require(taxPercentages[_receiver] == 0, "Receiver already exists");
        taxPercentages[_receiver] = _percentage;
        taxReceiverList.push(_receiver);

        emit AddTaxReceiver(_receiver, _percentage);
    }

    function updateReceiverTax(
        address _receiver,
        uint256 _percentage
    ) external onlyOwner {
        require(taxPercentages[_receiver] > 0);
        emit UpdateReceiverTax(
            _receiver,
            taxPercentages[_receiver],
            _percentage
        );
        taxPercentages[_receiver] = _percentage;
    }

    function removeTaxReceiver(uint256 _index) external onlyOwner {
        require(_index < taxReceiverList.length);
        emit RemoveTaxReceiver(taxReceiverList[_index]);
        taxPercentages[taxReceiverList[_index]] = 0;
        taxReceiverList[_index] = taxReceiverList[taxReceiverList.length - 1];
        taxReceiverList.pop();
    }

    function updateThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 0, "Value must be greater than 0");
        threshold = _threshold;
    }

    function updateTax(uint256 _fee, bool buy) external onlyOwner {
        if (buy) {
            require(_fee <= buyFee, "Fee > buyFee");
        } else {
            require(_fee <= sellFee, "Fee > sellFee");
        }

        emit UpdateFee(buy ? buyFee : sellFee, _fee);
        buy ? buyFee = _fee : sellFee = _fee;
    }

    function calculateFeeAmount(
        uint256 _amount,
        uint256 _fee
    ) public pure returns (uint256) {
        return (_amount * _fee) / 100;
    }

    function getTaxAmount(
        uint256 _amount,
        bool buy
    ) public view returns (uint256) {
        return
            buy
                ? calculateFeeAmount(_amount, buyFee)
                : calculateFeeAmount(_amount, sellFee);
    }

    function calculateTransferAmount(
        uint256 _amount,
        uint256 _fee
    ) public pure returns (uint256) {
        return _amount - _fee;
    }

    function setRewardAddress(
        address _rewardAddress
    ) external onlyOwner isValidAddress(_rewardAddress) {
        WETH = _rewardAddress;
    }

    function setRouter(
        address _routerAddress
    ) external onlyOwner isValidAddress(_routerAddress) {
        routerAddress = _routerAddress;
    }

    function addTaxExempts(
        address _user
    ) external onlyOwner isValidAddress(_user) {
        taxExempts[_user] = true;
    }

    function removeTaxExempts(
        address _user
    ) external onlyOwner isValidAddress(_user) {
        taxExempts[_user] = false;
    }

    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _to
    ) internal {
        IERC20(_tokenIn).approve(routerAddress, _amountIn);

        address[] memory path;
        if (_tokenIn != address(WETH) && _tokenOut != address(WETH)) {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        } else {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        }

        IUniswapV2Router02(routerAddress)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountIn,
                0,
                path,
                _to,
                block.timestamp + 10 minutes
            );
    }


    function _taxEqualsHundred() internal view returns (bool) {
        uint256 sum = 0;
        for (uint256 i = 0; i < taxReceiverList.length; i++) {
            address account = taxReceiverList[i];
            sum += taxPercentages[account];
        }

        return (sum == 100);
    }
}
