// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { dTSLA } from "../src/dTSLA.sol";
import { IGetTslaReturnTypes } from "../src/interfaces/IGetTslaReturnTypes.sol";

contract DeployDTsla is Script {
    string constant alpacaMintSource = "./functions/sources/alpacaBalance.js";
    string constant alpacaRedeemSource = "./functions/sources/alpacaBalance.js";

    function run() external {
        // Get params
        IGetTslaReturnTypes.GetTslaReturnType memory tslaReturnType = getdTslaRequirements();

        // Actually deploy
        vm.startBroadcast();
        deployDTSLA(
            tslaReturnType.subId,
            tslaReturnType.mintSource,
            tslaReturnType.redeemSource,
            tslaReturnType.functionsRouter,
            tslaReturnType.donId,
            tslaReturnType.tslaFeed,
            tslaReturnType.usdcFeed,
            tslaReturnType.redemptionCoin,
            tslaReturnType.secretVersion,
            tslaReturnType.secretSlot
        );
        vm.stopBroadcast();
    }

    function getdTslaRequirements() public returns (IGetTslaReturnTypes.GetTslaReturnType memory) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address tslaFeed,
            address usdcFeed, /*address ethFeed*/
            ,
            address functionsRouter,
            bytes32 donId,
            uint64 subId,
            address redemptionCoin,
            ,
            ,
            ,
            uint64 secretVersion,
            uint8 secretSlot
        ) = helperConfig.activeNetworkConfig();

        if (
            tslaFeed == address(0) || usdcFeed == address(0) || functionsRouter == address(0) || donId == bytes32(0)
                || subId == 0
        ) {
            revert("something is wrong");
        }
        string memory mintSource = vm.readFile(alpacaMintSource);
        string memory redeemSource = vm.readFile(alpacaRedeemSource);
        return IGetTslaReturnTypes.GetTslaReturnType(
            subId,
            mintSource,
            redeemSource,
            functionsRouter,
            donId,
            tslaFeed,
            usdcFeed,
            redemptionCoin,
            secretVersion,
            secretSlot
        );
    }

    function deployDTSLA(
        uint64 subId,
        string memory mintSource,
        string memory redeemSource,
        address functionsRouter,
        bytes32 donId,
        address tslaFeed,
        address usdcFeed,
        address redemptionCoin,
        uint64 secretVersion,
        uint8 secretSlot
    )
        public
        returns (dTSLA)
    {
        dTSLA dTsla = new dTSLA(
            subId,
            mintSource,
            redeemSource,
            functionsRouter,
            donId,
            tslaFeed,
            usdcFeed,
            redemptionCoin,
            secretVersion,
            secretSlot
        );
        return dTsla;
    }
}
