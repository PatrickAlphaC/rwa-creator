// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { TokenBridge } from "../src/ccip/TokenBridge.sol";
import { WETH } from "../src/ccip/WETH.sol";

// Mumbai WETH: 0x089dc24123e0A27d44282A1CcC2fd815989E3300
// Mumbai TokenBridge: 0xa9aCB9825F3A152c9dA7386D711e4a50a066a87D
// Sepolia TokenBridge: 0x8Bd94F5E6024BBADB026E80D453f5F8fAB2bC5Cc

contract DeployHomeChainContracts is Script {
    function run() external {
        // Get params

        // Actually deploy
        vm.createSelectFork(vm.rpcUrl("mumbai"));
        // Mumbai is home base
        (address linkToken, address ccipRouter, uint64 ccipChainSelector) = getTokenBridgeRequirements();
        uint64 homeBaseChainSelector = ccipChainSelector;

        vm.startBroadcast();
        WETH weth = deployWETH();
        deployTokenBridge(ccipRouter, linkToken, address(weth), ccipChainSelector, ccipChainSelector);
        vm.stopBroadcast();

        vm.createSelectFork(vm.rpcUrl("sepolia"));
        vm.startBroadcast();
        // If we pass address(0) for weth, it will deploy a new BridgedWETH contract
        deployTokenBridge(ccipRouter, linkToken, payable(address(0)), homeBaseChainSelector, ccipChainSelector);
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
        (,,,,,,, address linkToken, address ccipRouter, uint64 sourceChainSelector) = helperConfig.activeNetworkConfig();
        return (linkToken, ccipRouter, sourceChainSelector);
    }
}
