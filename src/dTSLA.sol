// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

/**
 * @title GettingStartedFunctionsConsumer
 * @notice This is an example contract to show how to make HTTP requests using Chainlink
 * @dev This contract uses hardcoded values and should not be used in production.
 */
contract dTSLA is FunctionsClient, ConfirmedOwner, ERC20 {
    using FunctionsRequest for FunctionsRequest.Request;
    using OracleLib for AggregatorV3Interface;

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response(bytes32 indexed requestId, uint256 character, bytes response, bytes err);

    // Check to get the router address for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    address s_functionsRouter;

    // JavaScript source code
    // Fetch character name from the Star Wars API.
    // Documentation: https://swapi.info/people
    string s_source;

    //Callback gas limit
    uint32 gasLimit = 300000;
    uint64 immutable i_subId;

    // donID - Hardcoded for Mumbai
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    bytes32 s_donID;

    uint256 portfolioBalance;

    mapping(bytes32 requestId => uint256 amountRequested) public requestToAmount;
    mapping(bytes32 requestId => address requester) public requestToUser;

    address public i_tslaFeed;
    uint256 public constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 public constant PORTFOLIO_PRECISION = 1e18;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor(uint64 subId, string memory source, address functionsRouter, bytes32 donId, address tslaPriceFeed)
        FunctionsClient(functionsRouter)
        ConfirmedOwner(msg.sender)
        ERC20("Backed TSLA", "bTSLA")
    {
        s_source = source;
        s_functionsRouter = functionsRouter;
        s_donID = donId;
        i_tslaFeed = tslaPriceFeed;
        i_subId = subId;
    }

    /**
     * @notice Sends an HTTP request for character information
     * @return requestId The ID of the request
     */
    function sendMintRequest(uint256 amountOfTokensToMint) external onlyOwner returns (bytes32 requestId) {
        if (getCalculatedNewTotalValue(amountOfTokensToMint) > portfolioBalance) {
            revert("Not enough portfolio value to mint that many tokens");
        }
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_source); // Initialize the request with JS code

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(req.encodeCBOR(), i_subId, gasLimit, s_donID);
        requestToAmount[s_lastRequestId] = amountOfTokensToMint;

        return s_lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        uint256 amountOfTokensToMint = requestToAmount[requestId];
        if (getCalculatedNewTotalValue(amountOfTokensToMint) > portfolioBalance) {
            revert("Not enough portfolio value to mint that many tokens");
        }
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        portfolioBalance = uint256(bytes32(response));
        s_lastError = err;

        _mint(requestToUser[requestId], amountOfTokensToMint);
    }

    function getTslaPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(i_tslaFeed);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return uint256(price) * ADDITIONAL_FEED_PRECISION;
    }

    function getTotalUsdValue() public view returns (uint256) {
        return totalSupply() * getTslaPrice();
    }

    function getCalculatedNewTotalValue(uint256 addedNumberOfTsla) public view returns (uint256) {
        return (totalSupply() + addedNumberOfTsla) * getTslaPrice();
    }
}
