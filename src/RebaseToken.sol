//SPDX-License-Identifier:MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*

██████╗ ███████╗██████╗  █████╗ ███████╗███████╗    ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
██████╔╝█████╗  ██████╔╝███████║███████╗█████╗         ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
██╔══██╗██╔══╝  ██╔══██╗██╔══██║╚════██║██╔══╝         ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
██║  ██║███████╗██████╔╝██║  ██║███████║███████╗       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝

*/

/**
 * @title Rebase Token
 * @author Anuraag Chetia
 * @notice This is a cross chain rebase token that incentivises users to deposit into a vault
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate that is the global interst rate at the time of depositing
 */
contract RebaseToken is ERC20 {
    error RebaseToken_InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private constant PRECISION_FACTOR = 1e18;

    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    event InterestRateSet(uint256 indexed newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") {}

    /**
     * @notice Set the interest rate in the contract
     * @param _newInterestRate The new interest rate to set
     * @dev The interest rate can only be decreases
     */
    function setInterestRate(uint256 _newInterestRate) external {
        //Set the interest rate
        if (_newInterestRate < s_interestRate) {
            revert RebaseToken_InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice Mint the user tokens when they deposit into the vaul
     * @param _to The user to mint the tokens to
     * @param _amount The amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external {
        // Before minting new tokens, we need to mint the previous accrued interest.
        // **Accrued interest** - The interest that has been earned but not yet paid out
        _mintAccruedInterest(_to);
        //Set user interest rate
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Calculate the balance of the user including the interest that has accumulated since the last update.
     * (principal balance) + some interest that has accrued
     * @param _user The user to calculate the balance for
     * @return The balance of the user including the interest that has accumulated since the last update.
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // Get the current principal balance of the user (the number of tokens that have actually been minted to the user)
        // multiply the principal balance by the interest that has accumulated in the time since the balance was last updated
        return super.balanceOf(_user) * _calculatedUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;
        // why divide by precision here ?
        // because both super.balanceOf(_user) && _calculatedUserAccumulatedInterestSinceLastUpdate will return in 1e18
        // 1e18 * 1e18 would become 1e36 so we divide by 1e18 to reduce precision
    }

    /////////////////////////////////
    ////// INTERNAL FUNCTIONS ///////
    /////////////////////////////////

    function _calculatedUserAccumulatedInterestSinceLastUpdate(address _user)
        internal
        view
        returns (uint256 linearInterest)
    {
        // we need to calculate the interest that has accumulated since the last update
        // this is going to be linear growth with time
        // 1. calculate the time since the last update
        // 2/ calculate the amount of linear growth
        // principal amount + ( principal amount * user interest rate * time elapsed )
        // example:
        // deposit = 10 tokens
        // interest rate = 0.5 per second
        // time elapsed = 2 seconds
        // 10 + ( 10 * 0.5 * 2 ) = 20 tokens
        /* *********** */
        // principal amount + ( principal amount * user interest rate * time elapsed ) == princial amount( 1 + ( 1 * user interest rate * time elapsed))
        uint256 timeElapsed = block.timestamp - s_userInterestRate[_user];
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed);
    }

    function _mintAccruedInterest(address _user) internal {
        // get the rate of interest
        // mint the extra tokens earned
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
    }

    ///////////////////////////////
    ////// GETTER FUNCTIONS ///////
    ///////////////////////////////

    /**
     * @notice Gets the interest rate for the particular user
     * @param user The user to get the interest rate for
     * @return The interest rate for the user
     */
    function getUserInterestRate(address user) external view returns (uint256) {
        return s_userInterestRate[user];
    }
}
