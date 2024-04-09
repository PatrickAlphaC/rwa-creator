// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IRouterClient } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { OwnerIsCreator } from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import { CCIPReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import { BridgedWETH } from "./BridgedWETH.sol";

contract TokenBridge is OwnerIsCreator, CCIPReceiver {
    error TokenBridge__NotSupportedSelector(uint64 chainSelector);
    error TokenBridge__InvalidReceiver(address receiver);
    error TokenBridge__TransferFailed();
    error TokenBridge__NotEnoughValueSent(uint256 balance, uint256 value);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant GAS_LIMIT = 1_000_000;
    uint256 private constant BYTES4_SIZE = 4;

    LinkTokenInterface private immutable i_linkToken;
    mapping(uint64 => bool) private s_supportedChainSelectors;
    BridgedWETH private immutable i_weth; // This will be either the actual WETH token, or BridgedWETH
    uint64 private immutable i_wethHomeChainSelector;
    uint64 private immutable i_thisChainSelector;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event ChainSelectorSet(uint64 indexed chainId, bool indexed supported);
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address indexed receiver,
        bytes data,
        address sender,
        uint256 fees
    );

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlySupportedChainSelector(uint64 chainSelector) {
        if (!s_supportedChainSelectors[chainSelector]) {
            revert TokenBridge__NotSupportedSelector(chainSelector);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(
        address router,
        address link,
        address payable weth,
        uint64 wethHomeBaseChainSelector,
        uint64 thisChainSelector
    )
        CCIPReceiver(router)
    {
        i_linkToken = LinkTokenInterface(link);
        if (weth == address(0)) {
            i_weth = new BridgedWETH(address(this));
        } else {
            i_weth = BridgedWETH(weth);
        }
        i_wethHomeChainSelector = wethHomeBaseChainSelector;
        i_thisChainSelector = thisChainSelector;

        s_supportedChainSelectors[i_thisChainSelector] = true;
        s_supportedChainSelectors[i_wethHomeChainSelector] = true;
    }

    function setSupportedChain(uint64 chainId, bool supported) external onlyOwner {
        s_supportedChainSelectors[chainId] = supported;
        emit ChainSelectorSet(chainId, supported);
    }

    function sendWethPayNative(
        uint64 destinationChainSelector,
        address destinationBridgedWethAddress,
        address destinationChainReceiver,
        uint256 amount
    )
        external
        payable
        onlySupportedChainSelector(destinationChainSelector)
        returns (bytes32 messageId)
    {
        if (destinationChainReceiver == address(0)) {
            revert TokenBridge__InvalidReceiver(destinationChainReceiver);
        }
        if (destinationBridgedWethAddress == address(0)) {
            revert TokenBridge__InvalidReceiver(destinationBridgedWethAddress);
        }

        // We don't need or want them passing function selectors, just the amounts and chain.
        bytes memory mintData = abi.encode(destinationChainReceiver, amount);
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(destinationBridgedWethAddress, mintData);

        // Get the fee required to send the CCIP message
        uint256 fee = IRouterClient(i_ccipRouter).getFee(destinationChainSelector, evm2AnyMessage);
        if (fee > msg.value) {
            revert TokenBridge__NotEnoughValueSent(msg.value, fee);
        }

        // Send the CCIP message through the router and store the returned CCIP message ID
        messageId = IRouterClient(i_ccipRouter).ccipSend{ value: fee }(destinationChainSelector, evm2AnyMessage);

        // Emit an event with message details
        emit MessageSent(messageId, destinationChainSelector, destinationBridgedWethAddress, mintData, msg.sender, fee);

        bool success = i_weth.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert TokenBridge__TransferFailed();
        }
        if (i_thisChainSelector != i_wethHomeChainSelector) {
            // Burn the WETH if we're not at the "home base"
            i_weth.bridgeBurn(msg.sender, amount);
        }
        return messageId;
    }

    function _buildCCIPMessage(
        address destinationChainTokenAddress,
        bytes memory data
    )
        private
        pure
        returns (Client.EVM2AnyMessage memory)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return Client.EVM2AnyMessage({
            receiver: abi.encode(destinationChainTokenAddress), // ABI-encoded receiver address
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({ gasLimit: GAS_LIMIT })
            ),
            feeToken: address(0) // address(0) means you'll pay in the native asset
         });
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual override {
        (address destinationChainReceiver, uint256 amount) = abi.decode(message.data, (address, uint256));
        if (i_wethHomeChainSelector != i_thisChainSelector) {
            i_weth.bridgeMint(destinationChainReceiver, amount);
        } else {
            bool success = i_weth.transfer(destinationChainReceiver, amount);
            if (!success) {
                revert TokenBridge__TransferFailed();
            }
        }
    }

    function withdrawExtra() external onlyOwner {
        (bool succ,) = owner().call{ value: address(this).balance }("");
        if (!succ) {
            revert TokenBridge__TransferFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getHomeChainSelector() external view returns (uint64) {
        return i_wethHomeChainSelector;
    }

    function getThisChainSelector() external view returns (uint64) {
        return i_thisChainSelector;
    }

    function getWeth() external view returns (BridgedWETH) {
        return i_weth;
    }
}
