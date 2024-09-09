// SPDX-License-Identifier: BUSL-1.1
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IGovToken, IERC20UpgradeableTokenV1} from "./Interfaces.sol";

/**
 * @title VotingPowerExchange
 * @dev This contract allows users to exchange utilityToken(ERC20 token) for GovToken(voting power token).
 * @custom:security-contact dev@codefox.co.jp
 */
contract VotingPowerExchange is AccessControl, EIP712 {
    using SignatureChecker for address;

    // Errors
    error VotingPowerExchange__DefaultAdminCannotBeZero();
    error VotingPowerExchange__AmountIsZero();
    error VotingPowerExchange__HighestIdIsTooHigh();
    error VotingPowerExchange__AddressIsZero();
    error VotingPowerExchange__GovOrUtilAddressIsZero();
    error VotingPowerExchange__AmountIsTooSmall();
    error VotingPowerExchange__InvalidNonce();
    error VotingPowerExchange__SignatureExpired();
    error VotingPowerExchange__InvalidSignature();
    error VotingPowerExchange__LevelIsLowerThanExisting();
    error VotingPowerExchange__VotingPowerIsHigherThanCap(uint256 currentVotingPower);

    // Events
    event VotingPowerReceived(address indexed user, uint256 utilityTokenAmount, uint256 votingPowerAmount);
    event VotingPowerCapSet(uint256 votingPowerCap);

    // EIP-712 domain separator and type hash for the message
    bytes32 private constant _EXCHANGE_TYPEHASH =
        keccak256("Exchange(address sender,uint256 amount,bytes32 nonce,uint256 expiration)");

    // Roles for the contract. Default admin holds the highest authority to to set the manager and exchanger.
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant EXCHANGER_ROLE = keccak256("EXCHANGER_ROLE");
    // PRECISION values for the calculation
    uint256 private constant PRECISION_FIX = 1e9;
    uint256 private constant PRECISION_FACTOR = 10;
    uint256 private constant PRECISION = 1e18;

    // token instances
    IGovToken private immutable govToken;
    IERC20UpgradeableTokenV1 private immutable utilityToken;

    // mapping to store the nonce of the user
    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;
    // voting power cap for limiting the voting power
    uint256 private votingPowerCap;

    /// @notice The constructor of the VotingPowerExchange contract
    /// @param _govToken The address of the GovToken contract
    /// @param _utilityToken The address of the ERC20 token contract
    /// @param defaultAdmin The address of the default admin
    /// @param manager The address of the manager
    /// @param exchanger The address of the exchanger
    constructor(address _govToken, address _utilityToken, address defaultAdmin, address manager, address exchanger)
        EIP712("VotingPowerExchange", "1")
    {
        if (defaultAdmin == address(0)) revert VotingPowerExchange__DefaultAdminCannotBeZero();
        if (_govToken == address(0) || _utilityToken == address(0)) {
            revert VotingPowerExchange__GovOrUtilAddressIsZero();
        }

        govToken = IGovToken(_govToken);
        utilityToken = IERC20UpgradeableTokenV1(_utilityToken);
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MANAGER_ROLE, manager);
        _grantRole(EXCHANGER_ROLE, exchanger);
        _setVotingPowerCap(100 * 1e18);
    }

    ////////////////////////////////////////////
    /////// External & Public functions ////////
    ////////////////////////////////////////////
    /**
     * @notice Exchanges utility token for voting power token using sender's signature to check the intention of the user.
     * @notice Increased level means the amount of voting power token to mint. The level is equal to the minted token amount onchian. The real voting power when people vote can be different through some off-chain handling.
     * @dev The main function of this contract.
     * @dev The user must sign the exchange message with the sender address, amount and nonce.
     * @dev Using EIP-712 to validate the signature.
     * @dev The amount of utilityToken to exchange must be greater than 1e15 to avoid the pricision loss in the calculation.
     * @param sender The address of the user who wants to exchange utilityToken for voting power token.
     * @param amount The amount of utilityToken to exchange.
     * @param nonce The nonce to prevent replay attacks.
     * @param expiration The expiration time of the signature.
     * @param signature The signature of the user to validate the voting power exchanging intention.
     */
    function exchange(address sender, uint256 amount, bytes32 nonce, uint256 expiration, bytes calldata signature)
        external
        onlyRole(EXCHANGER_ROLE)
    {
        if (sender == address(0)) revert VotingPowerExchange__AddressIsZero();
        if (amount < 1e15) revert VotingPowerExchange__AmountIsTooSmall();
        if (authorizationState(sender, nonce)) revert VotingPowerExchange__InvalidNonce();
        if (block.timestamp > expiration) revert VotingPowerExchange__SignatureExpired();
        // check the current gove token balance of the sender
        uint256 currentVotingPower = govToken.balanceOf(sender);
        if (currentVotingPower >= votingPowerCap) {
            revert VotingPowerExchange__VotingPowerIsHigherThanCap(currentVotingPower);
        }

        // create the digest for EIP-712 and validate the signature by the `sender`
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(_EXCHANGE_TYPEHASH, sender, amount, nonce, expiration)));
        if (!sender.isValidSignatureNow(digest, signature)) revert VotingPowerExchange__InvalidSignature();

        // set the nonce as true after validating the signature
        _authorizationStates[sender][nonce] = true;

        uint256 currentBurnedAmount = govToken.burnedAmountOfUtilToken(sender);

        // TODO: change the logics here according to `calculateIncrementedVotingPower` etc
        // calculate the amount of voting power token amount to mint
        // increased voting power = increased level = increased token amount of govToken
        uint256 increasedVotingPower = calculateIncreasedVotingPower(amount, currentBurnedAmount);

        uint256 burningTokenAmount = amount;
        // check the level cap to make sure it can only reach the cap but not to be over it
        if (currentVotingPower + increasedVotingPower > votingPowerCap) {
            increasedVotingPower = votingPowerCap - currentVotingPower;
            burningTokenAmount = calculateRequiredAmountToBeBurned(increasedVotingPower, currentBurnedAmount);
        }

        // burn utilityToken from the `sender`
        utilityToken.burnByBurner(msg.sender, burningTokenAmount);

        // update the burned amount of the `sender`
        govToken.setBurnedAmountOfUtilToken(sender, currentBurnedAmount + burningTokenAmount);

        // mint govToken to the user and emit event
        govToken.mint(sender, increasedVotingPower);
        emit VotingPowerReceived(msg.sender, burningTokenAmount, increasedVotingPower);
    }

    /**
     * @notice Set the voting power cap
     * @dev This function is for the manager to set the voting power cap
     * @param _votingPowerCap The new voting power cap
     */
    function setVotingPowerCap(uint256 _votingPowerCap) external onlyRole(MANAGER_ROLE) {
        if (_votingPowerCap <= votingPowerCap) revert VotingPowerExchange__LevelIsLowerThanExisting();
        _setVotingPowerCap(_votingPowerCap);
    }

    /// @notice Check the authorizer's nonce is used or not.
    /// @dev This function reads the mapping `_authorizationStates`.
    /// @return A bool to show if the nonce is used.
    function authorizationState(address authorizer, bytes32 nonce) public view returns (bool) {
        return _authorizationStates[authorizer][nonce];
    }

    ////////////////////////////////////////////
    /////// Internal & Private functions ///////
    ////////////////////////////////////////////
    /**
     * @notice Set the voting power cap
     * @dev This function is for internal use to set the voting power cap
     * @param _votingPowerCap The new voting power cap
     */
    function _setVotingPowerCap(uint256 _votingPowerCap) internal {
        votingPowerCap = _votingPowerCap;
        emit VotingPowerCapSet(_votingPowerCap);
    }

    ////////////////////////////////////
    /////// pure/view functions ////////
    ////////////////////////////////////
    // TODO: delete this function
    /**
     * @notice Calculate the increased voting power based on the amount of utility token to burn
     * @dev This function calculates the increased voting power based on the square root of the burned amount
     * @dev The formula is: `(sqrt(currentBurnedAmount + amount) - sqrt(currentBurnedAmount)) / 10`, which allows this to happen: e.g. 1,000,000 utility token can be burned to get 100 voting power.
     * @param amount The amount of utility token to burn
     * @param currentBurnedAmount The current burned amount of the user
     * @return increasedVotingPower The increased voting power
     */
    function calculateIncreasedVotingPower(uint256 amount, uint256 currentBurnedAmount) public pure returns (uint256) {
        uint256 increasedVotingPower = (
            Math.sqrt((currentBurnedAmount + amount) * PRECISION) - Math.sqrt(currentBurnedAmount * PRECISION)
        ) / PRECISION_FACTOR;
        return increasedVotingPower;
    }

    // TODO: delete this function
    /**
     * @notice Calculate the amount of tokens to burn (amount) to achieve the desired increased voting power
     * @dev This function calculates the amount based on the reverse calculation of the `calculateIncreasedVotingPower` function
     * @param increasedVotingPower The desired increased level
     * @param currentBurnedAmount The current burned amount of the user
     * @return amount The amount of tokens to be burned
     */
    function calculateRequiredAmountToBeBurned(uint256 increasedVotingPower, uint256 currentBurnedAmount)
        public
        pure
        returns (uint256)
    {
        // calculate sqrt(currentBurnedAmount * PRECISION)
        uint256 sqrtCurrent = Math.sqrt(currentBurnedAmount * PRECISION);
        // calculate increasedVotingPower * PRECISION_FACTOR
        uint256 votingPowerWithPrecision = increasedVotingPower * PRECISION_FACTOR;
        // calculate new sqrt
        uint256 sqrtNew = sqrtCurrent + votingPowerWithPrecision;
        // calculate new sqrt's power 2 and set its prEcision as 18
        uint256 sqrtNewSquared = (sqrtNew * sqrtNew) / PRECISION;
        // calculate the final amount
        uint256 amount = sqrtNewSquared - currentBurnedAmount;
        return amount;
    }

    // TODO: test this function
    /**
     * @notice Calculate the increased voting power based on the amount of utility token to burn
     * @dev This function calculates the increased voting power based on the difference of the voting power from the burned amount
     * @param amount The amount of utility token to burn
     * @param currentBurnedAmount The current burned amount of the user
     * @return increasedVotingPower The increased voting power
     */
    function calculateIncrementedVotingPower(uint256 amount, uint256 currentBurnedAmount)
        public
        pure
        returns (uint256)
    {
        return calculateVotingPowerFromBurnedAmount(amount + currentBurnedAmount)
            - calculateVotingPowerFromBurnedAmount(currentBurnedAmount);
    }

    // TODO: test this function
    /**
     * @notice Calculate the voting power based on the burned amount
     * @dev This function calculates the voting power based on the burned amount
     * @dev The formula is: `(2*SQRT(306.25 + 30*x) - 5) / 30 - 1`, which means: e.g. 3,350 utility token can be burned to get 20 voting power.
     * @dev 0 utility token burned menas getting 0 voting power.
     * @dev If the amount is less than 12e8, the result will be 0.
     * @param amount The amount of utility token to burn
     * @return votingPower The voting power
     */
    function calculateVotingPowerFromBurnedAmount(uint256 amount) public pure returns (uint256) {
        // calculate 306.25 + 30*x
        uint256 innerValue = (30625 * 1e16 + 30 * amount);
        // calculate 2*SQRT(306.25 + 30*x)
        uint256 sqrtPart = 2 * Math.sqrt(innerValue) * PRECISION_FIX;
        // calculate (2*SQRT(306.25+30*x)-5)/30 - 1
        uint256 result = (uint256(sqrtPart) - 5 * PRECISION) / 30 - PRECISION;
        return result;
    }

    // TODO: test this function
    function calculateIncrementedBurningAmount(uint256 increasedVotingPower, uint256 currentVotingPower)
        public
        pure
        returns (uint256)
    {
        return calculateBurningAmountFromVotingPower(currentVotingPower + increasedVotingPower)
            - calculateBurningAmountFromVotingPower(currentVotingPower);
    }

    // TODO: test this function
    function calculateBurningAmountFromVotingPower(uint256 votingPowerAmount) public pure returns (uint256) {
        // calculate this: y = (15*x^2+35*x)/2
        uint256 term = 15 * (votingPowerAmount * votingPowerAmount) / PRECISION + 35 * votingPowerAmount;
        uint256 result = term / 2;
        return result;
    }

    /**
     * @notice returns the current voting power cap
     * @dev This function is for convenience to check the current voting power cap
     */
    function getVotingPowerCap() external view returns (uint256) {
        return votingPowerCap;
    }

    /**
     * @notice returns all the immutable and constant addresses and values
     * @dev This function is for convenience to check the addresses and values
     */
    function getConstants()
        external
        pure
        returns (bytes32 __EXCHANGE_TYPEHASH, uint256 _PRECISION_FIX, uint256 _PRECISION_FACTOR, uint256 _PRECISION)
    {
        __EXCHANGE_TYPEHASH = _EXCHANGE_TYPEHASH;
        _PRECISION_FIX = PRECISION_FIX;
        _PRECISION_FACTOR = PRECISION_FACTOR;
        _PRECISION = PRECISION;
    }

    /**
     * @notice returns the addresses of the utilityToken and govToken
     * @dev This function is for convenience to check the addresses of the tokens
     */
    function getTokenAddresses() external view returns (address _utilityToken, address _govToken) {
        _utilityToken = address(utilityToken);
        _govToken = address(govToken);
    }
}
