// SPDX-License-Identifier: BUSL-1.1
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IGovToken} from "./Interfaces.sol";
import {IERC20UpgradeableTokenV1} from "./Interfaces.sol";

/**
 * @title VotingPowerExchange
 * @dev This contract allows users to exchange utilityToken(ERC20 token) for GovToken(voting power token).
 * @custom:security-contact dev@codefox.co.jp
 */
contract VotingPowerExchange is Ownable, EIP712 {
    using SignatureChecker for address;

    error VotingPowerExchange__AmountIsZero();
    error VotingPowerExchange__HighestIdIsTooHigh();
    error VotingPowerExchange__AddressIsZero();
    error VotingPowerExchange__InvalidNonce();
    error VotingPowerExchange__SignatureExpired();
    error VotingPowerExchange__InvalidSignature();
    error VotingPowerExchange__LevelIsLowerThanExisting();
    error VotingPowerExchange__LevelIsHigherThanCap();

    event VotingPowerReceived(address indexed user, uint256 utilityTokenAmount, uint256 votingPowerAmount);
    event HighsetIdSet(uint256 highestId);

    // EIP-712 domain separator and type hash for the message
    bytes32 private constant _EXCHANGE_TYPEHASH =
        keccak256("Exchange(address sender,uint256 amount,bytes32 nonce,uint256 expiration)");

    // PRICISION values for the calculation
    uint256 private constant PRICISION_FIX = 1e9;
    uint256 private constant PRICISION_FACTOR = 10;
    uint256 private constant PRICISION = 1e18;

    // token instances
    IGovToken private immutable govToken;
    IERC20UpgradeableTokenV1 private immutable utilityToken;

    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;
    uint256 private votingPowerCap;

    constructor(IGovToken _govToken, IERC20UpgradeableTokenV1 _utilityToken)
        Ownable(msg.sender)
        EIP712("VotingPowerExchange", "1")
    {
        govToken = _govToken;
        utilityToken = _utilityToken;
        _setLevelCap(100);
    }

    ////////////////////////////////////////////
    /////// External & Public functions ////////
    ////////////////////////////////////////////
    /**
     * @notice Exchanges utility token for voting power token using sender's signature to check the intention of the user.
     * @notice Increased level means the amount of voting power token to mint.
     * @notice The level is equal to the minted token amount onchian. The real voting power when people vote can be different through some off-chain handling.
     * @dev The main function of this contract.
     * @dev The user must sign the exchange message with the sender address, amount and nonce.
     * @dev Using EIP-712 to validate the signature.
     * @param sender The address of the user who wants to exchange utilityToken for voting power token.
     * @param amount The amount of utilityToken to exchange.
     * @param nonce The nonce to prevent replay attacks.
     * @param signature The signature of the user to validate the exchange intention.
     */
    // TODO: check the level cap and handle the burning amount
    function exchange(address sender, uint256 amount, bytes32 nonce, uint256 expiration, bytes calldata signature)
        external
        onlyOwner
    {
        if (sender == address(0)) revert VotingPowerExchange__AddressIsZero();
        if (amount == 0) revert VotingPowerExchange__AmountIsZero();
        if (authorizationState(sender, nonce)) revert VotingPowerExchange__InvalidNonce();
        if (block.timestamp > expiration) revert VotingPowerExchange__SignatureExpired();
        // check the current gove token balance of the sender
        uint256 currentVotingPower = govToken.balanceOf(sender);
        if (currentVotingPower >= votingPowerCap) revert VotingPowerExchange__LevelIsHigherThanCap();

        // Create the digest for EIP-712 and validate the signature by the `sender`
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(_EXCHANGE_TYPEHASH, sender, amount, nonce, expiration)));
        if (!sender.isValidSignatureNow(digest, signature)) revert VotingPowerExchange__InvalidSignature();

        // set the nonce as true after validating the signature
        _authorizationStates[sender][nonce] = true;

        uint256 currentBurnedAmount = govToken.burnedAmountOfUtilToken(sender);

        // Calculate the amount of voting power token amount to mint
        // increased level = increased token amount of govToken
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

    function setLevelCap(uint256 _votingPowerCap) external onlyOwner {
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
    function _setLevelCap(uint256 _votingPowerCap) internal onlyOwner {
        votingPowerCap = _votingPowerCap;
    }

    ////////////////////////////////////
    /////// pure/view functions ////////
    ////////////////////////////////////

    function calculateIncreasedVotingPower(uint256 amount, uint256 currentBurnedAmount) public pure returns (uint256) {
        uint256 increasedVotingPower = (
            Math.sqrt((currentBurnedAmount + amount) * PRICISION) - Math.sqrt(currentBurnedAmount * PRICISION)
        ) / PRICISION_FACTOR;
        return increasedVotingPower;
    }

    /**
     * @notice Calculate the amount of tokens to burn (amount) to achieve the desired increased level
     * @param increasedLevel The desired increased level
     * @param currentBurnedAmount The current burned amount of the user
     * @return amount The amount of tokens to be burned
     */
    function calculateRequiredAmountTobeBurned(uint256 increasedLevel, uint256 currentBurnedAmount)
        public
        pure
        returns (uint256)
    {
        // calculate sqrt(currentBurnedAmount * PRICISION)
        uint256 sqrtCurrent = Math.sqrt(currentBurnedAmount * PRICISION);
        // calculate increasedLevel * PRICISION_FACTOR
        uint256 levelWithPrecision = increasedLevel * PRICISION_FACTOR;
        // calculate new sqrt
        uint256 sqrtNew = sqrtCurrent + levelWithPrecision;
        // calculate new sqrt's power 2 and set its pricision as 18
        uint256 sqrtNewSquared = (sqrtNew * sqrtNew) / PRICISION;
        // calculate the final amount
        uint256 amount = sqrtNewSquared - currentBurnedAmount;
        return amount;
    }

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

    function getTokenAddresses() external view returns (address _utilityToken, address _govToken) {
        _utilityToken = address(utilityToken);
        _govToken = address(govToken);
    }
}
