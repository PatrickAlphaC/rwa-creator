// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { OracleLib, AggregatorV3Interface } from "./libraries/OracleLib.sol";
import { console2 } from "forge-std/console2.sol";

/**
 * @title dTSLA
 * @notice This is our contract to make requests to the Alpaca API to mint TSLA-backed dTSLA tokens
 * @dev This contract is meant to be for educational purposes only
 */
contract dTSLA is FunctionsClient, ConfirmedOwner, ERC20 {
    using FunctionsRequest for FunctionsRequest.Request;
    using OracleLib for AggregatorV3Interface;

    error dTSLA__NotEnoughCollateral();

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response(bytes32 indexed requestId, uint256 character, bytes response, bytes err);

    uint32 private constant GAS_LIMIT = 300_000;
    uint256 private constant PRECISION = 1e18;
    uint64 immutable i_subId;

    // Check to get the router address for your supported network
    // https://docs.chain.link/chainlink-functions/supported-networks
    address s_functionsRouter;
    string s_source;

    // donID - Hardcoded for Mumbai
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    bytes32 s_donID;
    uint256 s_portfolioBalance;

    mapping(bytes32 requestId => uint256 amountRequested) public s_requestToAmount;
    mapping(bytes32 requestId => address requester) public s_requestToUser;

    address public i_tslaFeed;
    uint256 public constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 public constant PORTFOLIO_PRECISION = 1e18;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor(
        uint64 subId,
        string memory source,
        address functionsRouter,
        bytes32 donId,
        address tslaPriceFeed
    )
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
     * @dev If you pass 0, that will act just as a way to get an updated portfolio balance
     * @return requestId The ID of the request
     */
    function sendMintRequest(uint256 amountOfTokensToMint) external onlyOwner returns (bytes32 requestId) {
        if (getCalculatedNewTotalValue(amountOfTokensToMint) > s_portfolioBalance) {
            revert dTSLA__NotEnoughCollateral();
        }
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_source); // Initialize the request with JS code

        // Send the request and store the request ID
        requestId = _sendRequest(req.encodeCBOR(), i_subId, GAS_LIMIT, s_donID);
        s_requestToAmount[requestId] = amountOfTokensToMint;
        s_requestToUser[requestId] = msg.sender;

        return requestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory /* err */ ) internal override {
        uint256 amountOfTokensToMint = s_requestToAmount[requestId];
        s_portfolioBalance = uint256(bytes32(response));

        console2.log(amountOfTokensToMint);
        console2.log(getCalculatedNewTotalValue(amountOfTokensToMint));
        console2.log(s_portfolioBalance);

        if (getCalculatedNewTotalValue(amountOfTokensToMint) > s_portfolioBalance) {
            revert dTSLA__NotEnoughCollateral();
        }

        if (amountOfTokensToMint != 0) {
            _mint(s_requestToUser[requestId], amountOfTokensToMint);
        }
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getPortfolioBalance() public view returns (uint256) {
        return s_portfolioBalance;
    }

    // TSLA USD has 8 decimal places, so we add an additional 10 decimal places
    function getTslaPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(i_tslaFeed);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return uint256(price) * ADDITIONAL_FEED_PRECISION;
    }

    function getTotalUsdValue() public view returns (uint256) {
        return (totalSupply() * getTslaPrice()) / PRECISION;
    }

    function getCalculatedNewTotalValue(uint256 addedNumberOfTsla) public view returns (uint256) {
        return ((totalSupply() + addedNumberOfTsla) * getTslaPrice()) / PRECISION;
    }
}
