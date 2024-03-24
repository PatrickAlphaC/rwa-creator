// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {dTSLA} from "../src/dTSLA.sol";

contract DeployDTsla is Script {
    string constant alpacaSource = "./functions/sources/alpacaBalance.js";

    function run() external {
        // Get params
        (uint64 subId, string memory source, address functionsRouter, bytes32 donId, address tslaFeed) =
            getdTslaRequirements();

        // Actually deploy
        vm.startBroadcast();
        deployDTSLA(subId, source, functionsRouter, donId, tslaFeed);
        vm.stopBroadcast();
    }

    function getdTslaRequirements() public returns (uint64, string memory, address, bytes32, address) {
        HelperConfig helperConfig = new HelperConfig();
        (address tslaFeed, /*address ethFeed*/, address functionsRouter, bytes32 donId, uint64 subId) =
            helperConfig.activeNetworkConfig();

        if (tslaFeed == address(0)) {
            revert("something is wrong");
        }
        string memory source = vm.readFile(alpacaSource);
        return (subId, source, functionsRouter, donId, tslaFeed);
    }

    function deployDTSLA(uint64 subId, string memory source, address functionsRouter, bytes32 donId, address tslaFeed)
        public
        returns (dTSLA)
    {
        dTSLA dTsla = new dTSLA(subId, source, functionsRouter, donId, tslaFeed);
        return dTsla;
    }
}
