// SPDX-License-Identifier: BUSL-1.1
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IGovToken} from "./Interfaces.sol";
import {IERC20UpgradeableTokenV1} from "./Interfaces.sol";

/**
 * @title VotingPowerExchange
 * @dev This contract allows users to exchange utilityToken(ERC20 token) for GovToken(voting power token).
 * @custom:security-contact dev@codefox.co.jp
 */
contract VotingPowerExchange is AccessControl, EIP712 {
    using SignatureChecker for address;

    // Errors
    error VotingPowerExchange__AmountIsZero();
    error VotingPowerExchange__HighestIdIsTooHigh();
    error VotingPowerExchange__AddressIsZero();
    error VotingPowerExchange__InvalidNonce();
    error VotingPowerExchange__SignatureExpired();
    error VotingPowerExchange__InvalidSignature();
    error VotingPowerExchange__LevelIsLowerThanExisting();
    error VotingPowerExchange__LevelIsHigherThanCap();

    // Events
    event VotingPowerReceived(address indexed user, uint256 utilityTokenAmount, uint256 votingPowerAmount);
    event VotingPowerCapSet(uint256 votingPowerCap);

    // EIP-712 domain separator and type hash for the message
    bytes32 private constant _EXCHANGE_TYPEHASH =
        keccak256("Exchange(address sender,uint256 amount,bytes32 nonce,uint256 expiration)");

    // Roles for the contract. Default admin holds the highest authority to to set the manager and exchanger.
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant EXCHANGER_ROLE = keccak256("EXCHANGER_ROLE");
    // PRICISION values for the calculation
    uint256 private constant PRICISION_FIX = 1e9;
    uint256 private constant PRICISION_FACTOR = 10;
    uint256 private constant PRICISION = 1e18;

    // token instances
    IGovToken private immutable govToken;
    IERC20UpgradeableTokenV1 private immutable utilityToken;

    // mapping to store the nonce of the user
    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;
    // voting power cap
    uint256 private votingPowerCap;

    /// constructor function of the contract.
    /// @param _govToken The address of the GovToken contract
    /// @param _utilityToken The address of the ERC20 token contract
    /// @param defaultAdmin The address of the default admin
    /// @param manager The address of the manager
    /// @param exchanger The address of the exchanger
    constructor(
        IGovToken _govToken,
        IERC20UpgradeableTokenV1 _utilityToken,
        address defaultAdmin,
        address manager,
        address exchanger
    ) EIP712("VotingPowerExchange", "1") {
        govToken = _govToken;
        utilityToken = _utilityToken;
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MANAGER_ROLE, manager);
        _grantRole(EXCHANGER_ROLE, exchanger);
        _setLevelCap(100);
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
     * @param sender The address of the user who wants to exchange utilityToken for voting power token.
     * @param amount The amount of utilityToken to exchange.
     * @param nonce The nonce to prevent replay attacks.
     * @param signature The signature of the user to validate the exchange intention.
     */
    function exchange(address sender, uint256 amount, bytes32 nonce, uint256 expiration, bytes calldata signature)
        external
        onlyRole(EXCHANGER_ROLE)
    {
        if (sender == address(0)) revert VotingPowerExchange__AddressIsZero();
        if (amount == 0) revert VotingPowerExchange__AmountIsZero();
        if (authorizationState(sender, nonce)) revert VotingPowerExchange__InvalidNonce();
        if (block.timestamp > expiration) revert VotingPowerExchange__SignatureExpired();
        // check the current gove token balance of the sender
        uint256 currentVotingPower = govToken.balanceOf(sender);
        if (currentVotingPower >= votingPowerCap) revert VotingPowerExchange__LevelIsHigherThanCap();

        // create the digest for EIP-712 and validate the signature by the `sender`
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(_EXCHANGE_TYPEHASH, sender, amount, nonce, expiration)));
        if (!sender.isValidSignatureNow(digest, signature)) revert VotingPowerExchange__InvalidSignature();

        // set the nonce as true after validating the signature
        _authorizationStates[sender][nonce] = true;

        uint256 currentBurnedAmount = govToken.burnedAmountOfUtilToken(sender);

        // calculate the amount of voting power token amount to mint
        // increased voting power = increased level = increased token amount of govToken
        uint256 increasedVotingPower = calculateIncreasedVotingPower(amount, currentBurnedAmount);

        uint256 burningTokenAmount = amount;
        // check the level cap to make sure it can only reach the cap but not to be over it
        if (currentVotingPower + increasedVotingPower > votingPowerCap) {
            increasedVotingPower = votingPowerCap - currentVotingPower;
            burningTokenAmount = calculateRequiredAmountTobeBurned(increasedVotingPower, currentBurnedAmount);
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
    function setLevelCap(uint256 _votingPowerCap) external onlyRole(MANAGER_ROLE) {
        if (_votingPowerCap < votingPowerCap) revert VotingPowerExchange__LevelIsLowerThanExisting();
        _setLevelCap(_votingPowerCap);
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
    function _setLevelCap(uint256 _votingPowerCap) internal {
        votingPowerCap = _votingPowerCap;
        emit VotingPowerCapSet(_votingPowerCap);
    }

    ////////////////////////////////////
    /////// pure/view functions ////////
    ////////////////////////////////////
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
            Math.sqrt((currentBurnedAmount + amount) * PRICISION) - Math.sqrt(currentBurnedAmount * PRICISION)
        ) / PRICISION_FACTOR;
        return increasedVotingPower;
    }

    /**
     * @notice Calculate the amount of tokens to burn (amount) to achieve the desired increased voting power
     * @dev This function calculates the amount based on the reverse calculation of the `calculateIncreasedVotingPower` function
     * @param increasedVotingPower The desired increased level
     * @param currentBurnedAmount The current burned amount of the user
     * @return amount The amount of tokens to be burned
     */
    function calculateRequiredAmountTobeBurned(uint256 increasedVotingPower, uint256 currentBurnedAmount)
        public
        pure
        returns (uint256)
    {
        // calculate sqrt(currentBurnedAmount * PRICISION)
        uint256 sqrtCurrent = Math.sqrt(currentBurnedAmount * PRICISION);
        // calculate increasedVotingPower * PRICISION_FACTOR
        uint256 votingPowerWithPrecision = increasedVotingPower * PRICISION_FACTOR;
        // calculate new sqrt
        uint256 sqrtNew = sqrtCurrent + votingPowerWithPrecision;
        // calculate new sqrt's power 2 and set its pricision as 18
        uint256 sqrtNewSquared = (sqrtNew * sqrtNew) / PRICISION;
        // calculate the final amount
        uint256 amount = sqrtNewSquared - currentBurnedAmount;
        return amount;
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
        returns (bytes32 __EXCHANGE_TYPEHASH, uint256 _PRICISION_FIX, uint256 _PRICISION_FACTOR, uint256 _PRICISION)
    {
        /* solhint-disable */
        __EXCHANGE_TYPEHASH = _EXCHANGE_TYPEHASH;
        _PRICISION_FIX = PRICISION_FIX;
        _PRICISION_FACTOR = PRICISION_FACTOR;
        _PRICISION = PRICISION;
        /* solhint-enable */
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
