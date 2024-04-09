// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { TokenBridge } from "../src/ccip/TokenBridge.sol";

import { Script } from "forge-std/Script.sol";

contract Interactions is Script {
    function run() public {
        // TokenBridge bridge = TokenBridge(0xa9aCB9825F3A152c9dA7386D711e4a50a066a87D);
        // vm.startBroadcast();
        // bridge.sendWethPayNative{ value: 10 ether }(sepoliaChainSelector, sepoliaWeth, destinationChainReceiver,
        // amount);
        // vm.stopBroadcast();
    }
}
