// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBridgedWETH is IERC20 {
    function bridgeMint(address to, uint256 amount) external;
    function bridgeBurn(address from, uint256 amount) external;
}
