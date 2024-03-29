// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { dTSLA } from "../src/dTSLA.sol";

contract DeployDTsla is Script {
    string constant alpacaMintSource = "./functions/sources/alpacaBalance.js";
    string constant alpacaRedeemSource = "./functions/sources/alpacaBalance.js";

    function run() external {
        // Get params
        (
            uint64 subId,
            string memory mintSource,
            string memory redeemSource,
            address functionsRouter,
            bytes32 donId,
            address tslaFeed,
            address usdcFeed,
            address redemptionCoin
        ) = getdTslaRequirements();

        // Actually deploy
        vm.startBroadcast();
        deployDTSLA(subId, mintSource, redeemSource, functionsRouter, donId, tslaFeed, usdcFeed, redemptionCoin);
        vm.stopBroadcast();
    }

    function getdTslaRequirements()
        public
        returns (uint64, string memory, string memory, address, bytes32, address, address, address)
    {
        HelperConfig helperConfig = new HelperConfig();
        (
            address tslaFeed,
            address usdcFeed, /*address ethFeed*/
            ,
            address functionsRouter,
            bytes32 donId,
            uint64 subId,
            address redemptionCoin
        ) = helperConfig.activeNetworkConfig();

        if (
            tslaFeed == address(0) || usdcFeed == address(0) || functionsRouter == address(0) || donId == bytes32(0)
                || subId == 0
        ) {
            revert("something is wrong");
        }
        string memory mintSource = vm.readFile(alpacaMintSource);
        string memory redeemSource = vm.readFile(alpacaRedeemSource);
        return (subId, mintSource, redeemSource, functionsRouter, donId, tslaFeed, usdcFeed, redemptionCoin);
    }

    function deployDTSLA(
        uint64 subId,
        string memory mintSource,
        string memory redeemSource,
        address functionsRouter,
        bytes32 donId,
        address tslaFeed,
        address usdcFeed,
        address redemptionCoin
    )
        public
        returns (dTSLA)
    {
        dTSLA dTsla =
            new dTSLA(subId, mintSource, redeemSource, functionsRouter, donId, tslaFeed, usdcFeed, redemptionCoin);
        return dTsla;
    }
}
