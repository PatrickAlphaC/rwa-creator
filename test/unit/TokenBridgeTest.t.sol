// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { DeployHomeChainContracts } from "../../script/DeployHomeChainContracts.s.sol";
import { DeployNewChainContracts } from "../../script/DeployNewChainContracts.s.sol";
import { TokenBridge } from "../../src/ccip/TokenBridge.sol";
import { WETH } from "../../src/ccip/WETH.sol";
import { BridgedWETH } from "../../src/ccip/BridgedWETH.sol";
import { HelperConfig, MockCCIPRouter } from "../../script/HelperConfig.sol";
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract TokenBridgeTest is Test {
    WETH homeChainWETH;
    BridgedWETH newChainWETH;
    TokenBridge homeBridge;
    TokenBridge newBridge;
    MockCCIPRouter mockRouter;
    address SENDER = makeAddr("user");
    address RECEIVER = makeAddr("receiver");
    uint256 constant STARTING_AMOUNT = 10e18;

    uint64 constant HOME_CHAIN_SELECTOR = 1;
    uint64 constant NEW_CHAIN_SELECTOR = 2;
    uint256 constant GAS_LIMIT = 1_000_000;

    function setUp() public {
        DeployHomeChainContracts deployHomeChainContracts = new DeployHomeChainContracts();
        DeployNewChainContracts deployNewChainContracts = new DeployNewChainContracts();
        HelperConfig helperConfig = new HelperConfig();
        (,,,,,,, address linkToken, address ccipRouter,,,) = helperConfig.activeNetworkConfig();
        homeChainWETH = deployHomeChainContracts.deployWETH();
        mockRouter = MockCCIPRouter(ccipRouter);

        homeBridge = deployHomeChainContracts.deployTokenBridge(
            ccipRouter, linkToken, payable(address(homeChainWETH)), HOME_CHAIN_SELECTOR, HOME_CHAIN_SELECTOR
        );

        newBridge = deployNewChainContracts.deployTokenBridge(
            ccipRouter, linkToken, payable(address(0)), HOME_CHAIN_SELECTOR, NEW_CHAIN_SELECTOR
        );

        vm.prank(homeBridge.owner());
        homeBridge.setSupportedChain(NEW_CHAIN_SELECTOR, true);

        newChainWETH = newBridge.getWeth();
    }

    function testDeployments() public view {
        assertEq(homeBridge.getHomeChainSelector(), newBridge.getHomeChainSelector());
        assertEq(homeBridge.getThisChainSelector(), newBridge.getHomeChainSelector());
        assertTrue(homeBridge.getThisChainSelector() != newBridge.getThisChainSelector());
        assertTrue(homeBridge.getWeth() != newBridge.getWeth());
        assertTrue(address(newBridge.getWeth()) != address(0));
        assertTrue(address(homeBridge.getWeth()) != address(0));
    }

    function testSendTokens() public {
        vm.startPrank(SENDER);
        vm.deal(SENDER, STARTING_AMOUNT);
        homeChainWETH.deposit{ value: STARTING_AMOUNT }();
        homeChainWETH.approve(address(homeBridge), STARTING_AMOUNT);
        bytes32 messageId =
            homeBridge.sendWethPayNative(NEW_CHAIN_SELECTOR, address(newChainWETH), RECEIVER, STARTING_AMOUNT);
        vm.stopPrank();
        assert(messageId != bytes32(0));
        assert(homeChainWETH.balanceOf(address(homeBridge)) == STARTING_AMOUNT);
        assert(newChainWETH.balanceOf(RECEIVER) == 0);
        assert(newChainWETH.balanceOf(SENDER) == 0);
    }

    function testReceiveTokensNewChain() public {
        bytes memory mintData = abi.encode(RECEIVER, STARTING_AMOUNT);
        bytes32 messageId = _tokensSent();
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: messageId,
            sourceChainSelector: HOME_CHAIN_SELECTOR,
            sender: abi.encode(SENDER),
            data: mintData,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        vm.prank(address(mockRouter));
        newBridge.ccipReceive(message);

        // This should have minted the tokens on the new chain
        assert(newChainWETH.balanceOf(RECEIVER) == STARTING_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    function _tokensSent() internal returns (bytes32) {
        vm.startPrank(SENDER);
        vm.deal(SENDER, STARTING_AMOUNT);
        homeChainWETH.deposit{ value: STARTING_AMOUNT }();
        homeChainWETH.approve(address(homeBridge), STARTING_AMOUNT);
        bytes32 messageId =
            homeBridge.sendWethPayNative(NEW_CHAIN_SELECTOR, address(newChainWETH), RECEIVER, STARTING_AMOUNT);
        vm.stopPrank();
        return messageId;
    }
}
