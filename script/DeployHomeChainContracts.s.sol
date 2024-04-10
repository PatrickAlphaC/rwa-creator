// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { TokenBridge } from "../src/ccip/TokenBridge.sol";
import { WETH } from "../src/ccip/WETH.sol";

contract DeployHomeChainContracts is Script {
    uint64 constant HOME_BASE_CHAIN_SELECTOR = 12_532_609_583_862_916_517; // This is mumbai

    function run() external {
        // Get params
        (address linkToken, address ccipRouter, uint64 ccipChainSelector) = getTokenBridgeRequirements();

        // Actually deploy
        vm.startBroadcast();
        WETH weth = deployWETH();
        deployTokenBridge(ccipRouter, linkToken, address(weth), HOME_BASE_CHAIN_SELECTOR, ccipChainSelector);
        vm.stopBroadcast();
    }

    // How do you deploy these on different chains?
    function deployWETH() public returns (WETH) {
        WETH weth = new WETH();
        return weth;
    }

    function deployTokenBridge(
        address ccipRouter,
        address linkToken,
        address weth,
        uint64 homeBaseChainSelector,
        uint64 thisChainSelector
    )
        public
        returns (TokenBridge)
    {
        TokenBridge tokenBridge =
            new TokenBridge(ccipRouter, linkToken, payable(address(weth)), homeBaseChainSelector, thisChainSelector);
        return tokenBridge;
    }

    function getTokenBridgeRequirements() public returns (address, address, uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (,,,,,,, address linkToken, address ccipRouter, uint64 sourceChainSelector,,) =
            helperConfig.activeNetworkConfig();
        return (linkToken, ccipRouter, sourceChainSelector);
    }
}
