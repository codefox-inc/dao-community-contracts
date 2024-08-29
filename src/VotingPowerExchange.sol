// SPDX-License-Identifier: BUSL-1.1
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

interface IERC20UpgradeableTokenV1 {
    function mint(address account, uint256 amount) external;
    function burnByBurner(address account, uint256 amount) external;
}

interface IGovToken {
    function mint(address account, uint256 amount) external;
    function burnByBurner(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title VotingPowerExchange
 * @dev This contract allows users to exchange utilityToken(ERC20 token) for GovToken(voting power token).
 */
contract VotingPowerExchange is Ownable, EIP712 {
    using SignatureChecker for address;

    error VotingPowerExchange__AmountIsZero();
    error VotingPowerExchange__HighestIdIsTooHigh();
    error VotingPowerExchange__AddressIsZero();
    error VotingPowerExchange__InvalidNonce();
    error VotingPowerExchange__InvalidSignature();

    event VotingPowerReceived(address indexed user, uint256 utilityTokenAmount, uint256 votingPowerAmount);
    event HighsetIdSet(uint256 highestId);

    // TODO: consider adding a nonce state variable
    mapping(address => mapping(bytes32 => bool)) internal _authorizationStates;

    // EIP-712 domain separator and type hash for the message
    bytes32 private constant _EXCHANGE_TYPEHASH = keccak256("Exchange(address sender,uint256 amount,bytes32 nonce)");

    IGovToken public immutable govToken;
    IERC20UpgradeableTokenV1 public immutable utilityToken;
    IERC1155 public immutable erc1155Contract;

    uint256 public highestAmbassadorTokenId; // erc1155 token id
    mapping(address user => uint256 burnedAmount) public burnedAmount;

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

    // TODO: change and check the exchange rate calculation of the voting power exchange
    // TODO: consider adding a nonce to avoid replay attacks
    function exchange(address sender, uint256 amount, bytes32 nonce, bytes calldata signature) external onlyOwner {
        if (sender == address(0)) revert VotingPowerExchange__AddressIsZero();
        if (amount == 0) revert VotingPowerExchange__AmountIsZero();
        if (authorizationState(sender, nonce)) revert VotingPowerExchange__InvalidNonce();

        // Create the digest for EIP-712
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(_EXCHANGE_TYPEHASH, sender, amount, nonce)));
        // validate the signature of the user
        if (!sender.isValidSignatureNow(digest, signature)) revert VotingPowerExchange__InvalidSignature();

        // set the nonce as true after validating the signature
        _authorizationStates[sender][nonce] = true;

        utilityToken.burnByBurner(msg.sender, amount);

        uint256 currentBurnedAmount = burnedAmount[sender];
        // Calculate the amount of voting pwoer token amount to mint
        uint256 votingPowerAmountToMint = (sqrt(currentBurnedAmount + amount) - sqrt(currentBurnedAmount)) / 10;
        // update the burned amount of the user
        burnedAmount[sender] = currentBurnedAmount + amount;

        // mint govToken to the user and emit event
        govToken.mint(sender, votingPowerAmountToMint);
        emit VotingPowerReceived(msg.sender, amount, votingPowerAmountToMint);
    }

    function setHighestAmbassadorTokenId(uint256 _highestAmbassadorTokenId) external onlyOwner {
        _setHighestAmbassadorTokenId(_highestAmbassadorTokenId);
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

    function authorizationState(address authorizer, bytes32 nonce) public view returns (bool) {
        return _authorizationStates[authorizer][nonce];
    }

    // TODO: change this to implementation of OpenZeppelin's Babylonian method??
    /**
     * @dev Computes the square root of a given number using the Babylonian method.
     * @param x The number to compute the square root of.
     * @return The square root of the input number.
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function _setHighestAmbassadorTokenId(uint256 _highestAmbassadorTokenId) internal {
        if (_highestAmbassadorTokenId > 10) revert VotingPowerExchange__HighestIdIsTooHigh();
        highestAmbassadorTokenId = _highestAmbassadorTokenId;
        emit HighsetIdSet(_highestAmbassadorTokenId);
    }
}
