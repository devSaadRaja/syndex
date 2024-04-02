// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Taxable is Ownable {
    // ==================== STRUCTURE ==================== //

    address internal immutable tokenProxy;
    address internal immutable innerToken;

    uint256 public buyFee = 2; // 2%
    uint256 public sellFee = 2; // 2%
    uint256 public threshold = 0.1 * 1e18; // in WETH

    uint256 public currentFeeAmount = 0;

    mapping(address => bool) public pool;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => uint256) public feePercentage;
    address[] feeTakers;

    address public rewardAddr;
    address public routerAddr;

    // ==================== EVENTS ==================== //

    event SetPool(address poolAddress, bool val);
    event RemovePool(address poolAddress);
    event UpdateFee(uint256 percentage);
    event SetFeeTaker(address addr, uint256 percentage);
    event RemoveFeeTaker(address addr);

    // ==================== MODIFIERS ==================== //

    modifier isValidAddress(address account) {
        require(account != address(0), "Invalid address");
        _;
    }

    modifier onlyToken() {
        require(innerToken == msg.sender, "Not associated token");
        _;
    }

    // ==================== FUNCTIONS ==================== //

    constructor(
        address _proxy,
        address _token,
        address _rewardAddr,
        address _router
    ) Ownable(msg.sender) {
        tokenProxy = _proxy;
        innerToken = _token;
        rewardAddr = _rewardAddr;
        routerAddr = _router;
    }

    function getAllFeeTakers() external view returns (address[] memory) {
        return feeTakers;
    }

    function setPool(
        address poolAddress,
        bool val
    ) external onlyOwner isValidAddress(poolAddress) {
        pool[poolAddress] = val;

        emit SetPool(poolAddress, val);
    }

    function setFeeTaker(
        address _addr,
        uint256 _percentage
    ) external onlyOwner {
        if (feePercentage[_addr] == 0) feeTakers.push(_addr);
        feePercentage[_addr] = _percentage;

        emit SetFeeTaker(_addr, _percentage);
    }

    function removeFeeTaker(uint256 _index) external onlyOwner {
        require(_index < feeTakers.length);
        emit RemoveFeeTaker(feeTakers[_index]);
        feePercentage[feeTakers[_index]] = 0;
        feeTakers[_index] = feeTakers[feeTakers.length - 1];
        feeTakers.pop();
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

        buy ? buyFee = _fee : sellFee = _fee;
        emit UpdateFee(_fee);
    }

    function addToCurrentFeeAmount(uint256 amount) external onlyToken {
        currentFeeAmount += amount;
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
        rewardAddr = _rewardAddress;
    }

    function setRouter(
        address _routerAddress
    ) external onlyOwner isValidAddress(_routerAddress) {
        routerAddr = _routerAddress;
    }

    function setExcludeFromFee(
        address _user,
        bool _val
    ) external onlyOwner isValidAddress(_user) {
        isExcludedFromFee[_user] = _val;
    }

    function distributeTax() external {
        require(_taxEqualsHundred(), "Total tax percentage should be 100");
        _distribute();
    }

    function _distribute() internal {
        address[] memory path = new address[](2);
        path[0] = tokenProxy;
        path[1] = rewardAddr;

        for (uint256 i = 0; i < feeTakers.length; i++) {
            address account = feeTakers[i];
            uint256 toSendAmount = calculateFeeAmount(
                currentFeeAmount,
                feePercentage[account]
            );

            IERC20(path[0]).approve(routerAddr, toSendAmount);

            IUniswapV2Router02(routerAddr)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    toSendAmount,
                    0,
                    path,
                    account,
                    block.timestamp + 10 minutes
                );
        }

        currentFeeAmount = 0;
    }

    function _taxEqualsHundred() internal view returns (bool) {
        uint256 sum = 0;
        for (uint256 i = 0; i < feeTakers.length; i++) {
            address account = feeTakers[i];
            sum += feePercentage[account];
        }

        return (sum == 100);
    }
}
