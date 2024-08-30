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

interface IERC20UpgradeableTokenV1 {
    function mint(address account, uint256 amount) external;
    function burnByBurner(address account, uint256 amount) external;
}

interface IGovToken {
    function mint(address account, uint256 amount) external;
    function burnByBurner(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function burnedAmountOfUtilToken(address account) external view returns (uint256);
    function setBurnedAmountOfUtilToken(address account, uint256 amount) external;
}

/**
 * @title VotingPowerExchange
 * @dev This contract allows users to exchange utilityToken(ERC20 token) for GovToken(voting power token).
 */
contract VotingPowerExchange is Ownable, EIP712 {
    using Arrays for uint256[];
    using SignatureChecker for address;

    error VotingPowerExchange__AmountIsZero();
    error VotingPowerExchange__HighestIdIsTooHigh();
    error VotingPowerExchange__AddressIsZero();
    error VotingPowerExchange__InvalidNonce();
    error VotingPowerExchange__InvalidSignature();
    error VotingPowerExchange__LevelIsLowerThanExisting();

    event VotingPowerReceived(address indexed user, uint256 utilityTokenAmount, uint256 votingPowerAmount);
    event HighsetIdSet(uint256 highestId);

    // TODO: consider adding a nonce state variable
    mapping(address => mapping(bytes32 => bool)) internal _authorizationStates;
    uint256 public levelCap = 100;

    // EIP-712 domain separator and type hash for the message
    bytes32 private constant _EXCHANGE_TYPEHASH = keccak256("Exchange(address sender,uint256 amount,bytes32 nonce)");
    uint256 constant LEVEL_COUNT = 26;
    uint256 constant TOKEN_DECIMALS = 1e18;

    IGovToken public immutable govToken;
    IERC20UpgradeableTokenV1 public immutable utilityToken;
    IERC1155 public immutable erc1155Contract;

    uint256 public highestAmbassadorTokenId; // erc1155 token id
    // mapping(address user => uint256 burnedAmount) public burnedAmount;

    constructor(
        IGovToken _govToken,
        IERC20UpgradeableTokenV1 _utilityToken,
        IERC1155 _erc1155Contract,
        uint256 _highestTokenId // highest ambassador token id is 3 initially
    ) Ownable(msg.sender) EIP712("VotingPowerExchange", "1") {
        govToken = _govToken;
        utilityToken = _utilityToken;
        erc1155Contract = _erc1155Contract;
        _setHighestAmbassadorTokenId(_highestTokenId);
    }

    /**
     * @notice Exchanges utilityToken for voting power token using sender's signature to check the intention of the user.
     * @dev The main function of this contract.
     * @dev The user must sign the exchange message with the sender address, amount and nonce.
     * @dev Using EIP-712 to validate the signature.
     * @param sender The address of the user who wants to exchange utilityToken for voting power token.
     * @param amount The amount of utilityToken to exchange.
     * @param nonce The nonce to prevent replay attacks.
     * @param signature The signature of the user to validate the exchange intention.
     */
    // TODO: change and check the exchange rate calculation of the voting power exchange
    function exchange(address sender, uint256 amount, bytes32 nonce, bytes calldata signature) external onlyOwner {
        if (sender == address(0)) revert VotingPowerExchange__AddressIsZero();
        if (amount == 0) revert VotingPowerExchange__AmountIsZero();
        if (authorizationState(sender, nonce)) revert VotingPowerExchange__InvalidNonce();

        // Create the digest for EIP-712 and validate the signature by the `sender`
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(_EXCHANGE_TYPEHASH, sender, amount, nonce)));
        if (!sender.isValidSignatureNow(digest, signature)) revert VotingPowerExchange__InvalidSignature();

        // set the nonce as true after validating the signature
        _authorizationStates[sender][nonce] = true;

        uint256 currentBurnedAmount = govToken.burnedAmountOfUtilToken(sender);
        // Calculate the amount of voting pwoer token amount to mint
        uint256 votingPowerAmountToMint =
            (Math.sqrt(currentBurnedAmount + amount) - Math.sqrt(currentBurnedAmount)) * 1e9;
        // TODO: votingPower/10 = level?

        // burn utilityToken from the `sender`
        utilityToken.burnByBurner(msg.sender, amount);

        // update the burned amount of the `sender`
        govToken.setBurnedAmountOfUtilToken(sender, currentBurnedAmount + amount);

        // mint govToken to the user and emit event
        govToken.mint(sender, votingPowerAmountToMint);
        emit VotingPowerReceived(msg.sender, amount, votingPowerAmountToMint);
    }

    function setHighestAmbassadorTokenId(uint256 _highestAmbassadorTokenId) external onlyOwner {
        _setHighestAmbassadorTokenId(_highestAmbassadorTokenId);
    }

    function setLevelCap(uint256 _levelCap) external onlyOwner {
        if (_levelCap < levelCap) revert VotingPowerExchange__LevelIsLowerThanExisting();
        levelCap = _levelCap;
    }

    /**
     * @notice Returns the highest ERC1155 token ID held by a user.
     * @param user The address of the user.
     * @return highestId The highest ERC1155 token ID held by the user.
     */
    function getHighestERC1155TokenId(address user) public view returns (uint256 highestId) {
        // Iterate through a predefined range to find the highest token ID
        // In a real implementation, this range should be based on the actual token IDs that are mintable
        uint256 currentHighestId = highestId;
        for (uint256 i; i <= currentHighestId;) {
            if (erc1155Contract.balanceOf(user, i) > 0) {
                highestId = i;
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Check the authorizer's nonce is used or not.
    /// @dev This function reads the mapping `_authorizationStates`.
    /// @return A bool to show if the nonce is used.
    function authorizationState(address authorizer, bytes32 nonce) public view returns (bool) {
        return _authorizationStates[authorizer][nonce];
    }

    function _setHighestAmbassadorTokenId(uint256 _highestAmbassadorTokenId) internal {
        if (_highestAmbassadorTokenId > 10) revert VotingPowerExchange__HighestIdIsTooHigh();
        highestAmbassadorTokenId = _highestAmbassadorTokenId;
        emit HighsetIdSet(_highestAmbassadorTokenId);
    }
}
