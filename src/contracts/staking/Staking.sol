// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// import {intoUint256, ud} from "@prb/math/UD60x18.sol";

/**
 * @title Staking Contract
 * @dev This contract manages staking and rewards distribution for users.
 */
contract Staking is Ownable, ReentrancyGuard {
    // ==================== STRUCTURE ==================== //

    struct StakeData {
        uint256 balance; // staked amount
        uint256 locked; // locked time before unstake
        uint256 lastClaimed; // last time user has claimed
    }

    mapping(address => StakeData) public stakes;

    uint256 public APR = 14;

    uint256 public totalStaked;
    uint256 public warmupPeriod = 4 days;

    address public TOKEN = 0x2eA6CC1ac06fdC01b568fcaD8D842DEc3F2CE1aD; // Staked Token
    address public rewardToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH | mainnet address

    // ==================== EVENTS ==================== //

    event SetToken(address token);
    event SetWarmup(uint256 warmup);
    event SetRewardRate(uint256 rate);
    event SetRewardToken(address rewardToken);
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event ClaimRewards(address indexed user, uint256 amount);

    // ==================== MODIFIERS ==================== //

    modifier moreThanZero(uint256 value) {
        require(value > 0, "Value must be greater than 0");
        _;
    }

    modifier warmupPeriodEnded(address account) {
        require(
            stakes[account].locked <= block.timestamp,
            "Warmup Period not Ended!"
        );
        _;
    }

    modifier isBalanceAvailable(address account, uint256 amount) {
        require(stakes[account].balance >= amount, "Invalid amount");
        _;
    }

    modifier isValidAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    // ==================== CONSTRUCTOR ==================== //

    constructor(address _token, address _rewardToken) Ownable(msg.sender) {
        TOKEN = _token;
        rewardToken = _rewardToken;
    }

    // ==================== FUNCTIONS ==================== //

    /**
     * @dev Gets the staking details for a specific user.
     * @param account The user's address.
     * @return An array of stake data.
     */
    function getStakeDetails(
        address account
    ) external view returns (StakeData memory) {
        return stakes[account];
    }

    /**
     * @dev Sets the warmup period duration.
     * @param _warmupPeriod The warmup period duration.
     */
    function setWarmupPeriod(uint256 _warmupPeriod) external onlyOwner {
        warmupPeriod = _warmupPeriod;
        emit SetWarmup(_warmupPeriod);
    }

    /**
     * @dev Sets the reward address for staked token.
     * @param _tokenAddress The address of the token.
     */
    function setToken(
        address _tokenAddress
    ) external onlyOwner isValidAddress(_tokenAddress) {
        TOKEN = _tokenAddress;
        emit SetToken(TOKEN);
    }

    /**
     * @dev Sets the reward address for rewards distribution.
     * @param _rewardAddress The address of the reward token.
     */
    function setRewardToken(
        address _rewardAddress
    ) external onlyOwner isValidAddress(_rewardAddress) {
        rewardToken = _rewardAddress;
        emit SetRewardToken(rewardToken);
    }

    /**
     * @dev Sets the reward rate for rewards calculations.
     * @param _rate The reward rate.
     */
    function setRewardRate(
        uint256 _rate
    ) external onlyOwner moreThanZero(_rate) {
        APR = _rate;
        emit SetRewardRate(APR);
    }

    /**
     * @dev Stakes a specified amount of tokens.
     * @param amount The amount to stake.
     */
    function stake(uint256 amount) external moreThanZero(amount) {
        address account = msg.sender;

        bool success = IERC20(TOKEN).transferFrom(
            account,
            address(this),
            amount
        );
        require(success, "Transfer Failed");

        if (stakes[account].balance == 0) {
            stakes[account].lastClaimed = block.timestamp;
        }
        stakes[account].balance += amount;
        stakes[account].locked = block.timestamp + warmupPeriod;

        totalStaked += amount;

        emit Stake(account, amount);
    }

    /**
     * @dev Unstakes a specified amount of tokens from a specific stake position.
     * @param amount The amount to unstake.
     */
    function unstake(
        uint256 amount
    )
        external
        moreThanZero(amount)
        warmupPeriodEnded(msg.sender)
        isBalanceAvailable(msg.sender, amount)
    {
        address account = msg.sender;

        _claimReward(account);

        bool success = IERC20(TOKEN).transfer(account, amount);
        require(success, "Transfer Failed");

        totalStaked -= amount;
        stakes[account].balance -= amount;

        emit Unstake(account, amount);
    }

    /**
     * @dev Claims reward for caller.
     */
    function claimReward() external warmupPeriodEnded(msg.sender) {
        _claimReward(msg.sender);
    }

    /**
     * @dev Calculates the claimable rewards for a user.
     * @param account The user's address.
     * @return The claimable rewards amount.
     */
    function calculateRewards(address account) public view returns (uint256) {
        uint duration = block.timestamp - stakes[account].lastClaimed;
        uint256 reward = (stakes[account].balance * APR * duration) / 365 days;
        return reward / 100;
    }

    function _claimReward(address account) internal {
        uint256 amount = calculateRewards(account);
        require(amount > 0, "Nothing to claim.");

        bool success = IERC20(rewardToken).transfer(account, amount);
        require(success, "Transfer Failed");

        stakes[account].lastClaimed = block.timestamp;
        emit ClaimRewards(account, amount);
    }

    /**
     * @dev Withdraws funds from the contract to an external account.
     * @param account The recipient's address.
     * @param token The token to withdraw.
     * @param amount The amount to withdraw.
     */
    function withdrawFunds(
        address account,
        address token,
        uint256 amount
    ) external onlyOwner isValidAddress(account) {
        IERC20(token).transfer(account, amount);
    }

    /**
     * @dev Withdraws ETH from the contract to an external account.
     * @param account The recipient's address.
     * @param amount The amount to withdraw.
     */
    function withdrawETH(
        address account,
        uint256 amount
    ) external onlyOwner isValidAddress(account) {
        (bool success, ) = account.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
