// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

// These are the interfaces which got used in the VoingPowerExchange contract
interface IERC20UpgradeableTokenV1 {
    function mint(address account, uint256 amount) external;
    function burnByBurner(address account, uint256 amount) external;
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

interface IGovToken {
    function mint(address account, uint256 amount) external;
    function burnByBurner(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function burnedAmountOfUtilToken(address account) external view returns (uint256);
    function setBurnedAmountOfUtilToken(address account, uint256 amount) external;
}
