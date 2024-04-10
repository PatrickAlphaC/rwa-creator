// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { sTSLA } from "../src/sTSLA.sol";

contract DeploySTsla is Script {
    function run() external {
        // Get params
        (address tslaFeed, address ethFeed) = getdTslaRequirements();

        // Actually deploy
        vm.startBroadcast();
        deploySTSLA(tslaFeed, ethFeed);
        vm.stopBroadcast();
    }

    function getdTslaRequirements() public returns (address, address) {
        HelperConfig helperConfig = new HelperConfig();
        (address tslaFeed,, address ethFeed,,,,,,,,,) = helperConfig.activeNetworkConfig();

        if (tslaFeed == address(0) || ethFeed == address(0)) {
            revert("something is wrong");
        }
        return (tslaFeed, ethFeed);
    }

    function deploySTSLA(address tslaFeed, address ethFeed) public returns (sTSLA) {
        return new sTSLA(tslaFeed, ethFeed);
    }
}
