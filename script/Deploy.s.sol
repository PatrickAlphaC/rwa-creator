// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";

contract Deploy is Script {
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        // (address tslaFeed) = helperConfig.activeNetworkConfig();

        // if (tslaFeed == address(0)) {
        //     revert("something is wrong");
        // }

        // vm.startBroadcast();
        // new PriceFeedConsumer(priceFeed);
        // vm.stopBroadcast();
    }
}
