// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {BackedTSLA} from "../src/BackedTSLA.sol";

contract Deploy is Script {
    string constant alpacaSource = "./functions/sources/alpacaBalance.js";

    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        (address tslaFeed, /*address ethFeed*/, address functionsRouter, bytes32 donId, uint64 subId) =
            helperConfig.activeNetworkConfig();

        if (tslaFeed == address(0)) {
            revert("something is wrong");
        }

        string memory source = vm.readFile(alpacaSource);
        vm.startBroadcast();
        new BackedTSLA(subId, source, functionsRouter, donId, tslaFeed);
        vm.stopBroadcast();
    }
}
