// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./Proxy.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/ISynDex.sol";
import "../interfaces/ISupplySchedule.sol";

import "../libraries/SafeDecimalMath.sol";

contract SupplySchedule is Ownable, ISupplySchedule {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using Math for uint;

    bytes32 public constant CONTRACT_NAME = "SupplySchedule";

    // Time of the last inflation supply mint event
    uint public lastMintEvent;

    // Counter for number of weeks since the start of supply inflation
    uint public weekCounter;

    uint public constant INFLATION_START_DATE = 1551830400; // 2019-03-06T00:00:00+00:00

    // The number of SFCX rewarded to the caller of SynDex.mint()
    uint public minterReward = 100 * 1e18;

    // The number of SFCX minted per week
    uint public inflationAmount;

    uint public maxInflationAmount = 3e6 * 1e18; // max inflation amount 3,000,000

    // Address of the SynDexProxy for the onlySynDex modifier
    address payable public syndexProxy;

    // Max SFCX rewards for minter
    uint public constant MAX_MINTER_REWARD = 200 * 1e18;

    // How long each inflation period is before mint can be called
    uint public constant MINT_PERIOD_DURATION = 1 weeks;

    uint public constant MINT_BUFFER = 1 days;

    constructor(
        address _owner,
        uint _lastMintEvent,
        uint _currentWeek
    ) Ownable(_owner) {
        lastMintEvent = _lastMintEvent;
        weekCounter = _currentWeek;
    }

    // ========== VIEWS ==========

    /**
     * @return The amount of SFCX mintable for the inflationary supply
     */
    function mintableSupply() external view returns (uint) {
        uint totalAmount;

        if (!isMintable()) {
            return totalAmount;
        }

        // Get total amount to mint * by number of weeks to mint
        totalAmount = inflationAmount.mul(weeksSinceLastIssuance());

        return totalAmount;
    }

    /**
     * @dev Take timeDiff in seconds (Dividend) and MINT_PERIOD_DURATION as (Divisor)
     * @return Calculate the numberOfWeeks since last mint rounded down to 1 week
     */
    function weeksSinceLastIssuance() public view returns (uint) {
        // Get weeks since lastMintEvent
        // If lastMintEvent not set or 0, then start from inflation start date.
        uint timeDiff = lastMintEvent > 0
            ? block.timestamp.sub(lastMintEvent)
            : block.timestamp.sub(INFLATION_START_DATE);
        return timeDiff.div(MINT_PERIOD_DURATION);
    }

    /**
     * @return boolean whether the MINT_PERIOD_DURATION (7 days)
     * has passed since the lastMintEvent.
     * */
    function isMintable() public view returns (bool) {
        if (block.timestamp - lastMintEvent > MINT_PERIOD_DURATION) {
            return true;
        }
        return false;
    }

    // ========== MUTATIVE FUNCTIONS ==========

    /**
     * @notice Record the mint event from SynDex by incrementing the inflation
     * week counter for the number of weeks minted (probabaly always 1)
     * and store the time of the event.
     * @param supplyMinted the amount of SFCX the total supply was inflated by.
     * @return minterReward the amount of SFCX reward for caller
     * */
    function recordMintEvent(
        uint supplyMinted
    ) external onlySynDex returns (uint) {
        uint numberOfWeeksIssued = weeksSinceLastIssuance();

        // add number of weeks minted to weekCounter
        weekCounter = weekCounter.add(numberOfWeeksIssued);

        // Update mint event to latest week issued (start date + number of weeks issued * seconds in week)
        // 1 day time buffer is added so inflation is minted after feePeriod closes
        lastMintEvent = INFLATION_START_DATE
            .add(weekCounter.mul(MINT_PERIOD_DURATION))
            .add(MINT_BUFFER);

        emit SupplyMinted(
            supplyMinted,
            numberOfWeeksIssued,
            lastMintEvent,
            block.timestamp
        );
        return minterReward;
    }

    // ========== SETTERS ========== */

    /**
     * @notice Sets the reward amount of SFCX for the caller of the public
     * function SynDex.mint().
     * This incentivises anyone to mint the inflationary supply and the mintr
     * Reward will be deducted from the inflationary supply and sent to the caller.
     * @param amount the amount of SFCX to reward the minter.
     * */
    function setMinterReward(uint amount) external onlyOwner {
        require(
            amount <= MAX_MINTER_REWARD,
            "Reward cannot exceed max minter reward"
        );
        minterReward = amount;
        emit MinterRewardUpdated(minterReward);
    }

    /**
     * @notice Set the SynDexProxy should it ever change.
     * SupplySchedule requires SynDex address as it has the authority
     * to record mint event.
     * */
    function setSynDexProxy(address _syndexProxy) external onlyOwner {
        require(_syndexProxy != address(0), "Address cannot be 0");
        syndexProxy = payable(_syndexProxy);
        emit SynDexProxyUpdated(syndexProxy);
    }

    /**
     * @notice Set the weekly inflationAmount.
     * Protocol DAO sets the amount based on the currentTarget staking ratio
     * Will be replaced with on-chain calculation of the staking ratio
     * */
    function setInflationAmount(uint amount) external onlyOwner {
        require(amount <= maxInflationAmount, "Amount above maximum inflation");
        inflationAmount = amount;
        emit InflationAmountUpdated(inflationAmount);
    }

    function setMaxInflationAmount(uint amount) external onlyOwner {
        maxInflationAmount = amount;
        emit MaxInflationAmountUpdated(inflationAmount);
    }

    // ========== MODIFIERS ==========

    /**
     * @notice Only the SynDex contract is authorised to call this function
     * */
    modifier onlySynDex() {
        require(
            msg.sender == address(Proxy(syndexProxy).currentTarget()),
            "Only the syndex contract can perform this action"
        );
        _;
    }

    /* ========== EVENTS ========== */
    /**
     * @notice Emitted when the inflationary supply is minted
     * */
    event SupplyMinted(
        uint supplyMinted,
        uint numberOfWeeksIssued,
        uint lastMintEvent,
        uint timestamp
    );

    /**
     * @notice Emitted when the SFCX minter reward amount is updated
     * */
    event MinterRewardUpdated(uint newRewardAmount);

    /**
     * @notice Emitted when the Inflation amount is updated
     * */
    event InflationAmountUpdated(uint newInflationAmount);

    /**
     * @notice Emitted when the max Inflation amount is updated
     * */
    event MaxInflationAmountUpdated(uint newInflationAmount);

    /**
     * @notice Emitted when setSynDexProxy is called changing the SynDex Proxy address
     * */
    event SynDexProxyUpdated(address newAddress);
}
