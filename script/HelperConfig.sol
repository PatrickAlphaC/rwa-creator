// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { MockV3Aggregator } from "../src/test/mocks/MockV3Aggregator.sol";
import { MockFunctionsRouter } from "../src/test/mocks/MockFunctionsRouter.sol";
import { MockUSDC } from "../src/test/mocks/MockUSDC.sol";

contract HelperConfig {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address tslaPriceFeed;
        address usdcPriceFeed;
        address ethUsdPriceFeed;
        address functionsRouter;
        bytes32 donId;
        uint64 subId;
        address redemptionCoin;
    }

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

    // Mocks
    MockV3Aggregator public tslaFeedMock;
    MockV3Aggregator public ethUsdFeedMock;
    MockV3Aggregator public usdcFeedMock;
    MockUSDC public usdcMock;

    MockFunctionsRouter public functionsRouterMock;

    // TSLA USD, ETH USD, and USDC USD both have 8 decimals
    uint8 public constant DECIAMLS = 8;
    int256 public constant INITIAL_ANSWER = 2000e8;
    int256 public constant INITIAL_ANSWER_USD = 1e8;

    constructor() {
        chainIdToNetworkConfig[137] = getPolygonConfig();
        chainIdToNetworkConfig[80_001] = getMumbaiConfig();
        chainIdToNetworkConfig[31_337] = _setupAnvilConfig();
        activeNetworkConfig = chainIdToNetworkConfig[block.chainid];
    }

    function getPolygonConfig() internal pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            tslaPriceFeed: 0x567E67f456c7453c583B6eFA6F18452cDee1F5a8,
            usdcPriceFeed: 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7,
            ethUsdPriceFeed: 0xF9680D99D6C9589e2a93a78A04A279e509205945,
            functionsRouter: 0xdc2AAF042Aeff2E68B3e8E33F19e4B9fA7C73F10,
            donId: 0x66756e2d706f6c79676f6e2d6d61696e6e65742d310000000000000000000000,
            subId: 0, // TODO
            // USDC on Polygon
            redemptionCoin: 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359
        });
        // minimumRedemptionAmount: 30e6 // Please see your brokerage for min redemption amounts
        // https://alpaca.markets/support/crypto-wallet-faq
    }

    function getMumbaiConfig() internal pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            tslaPriceFeed: 0x1C2252aeeD50e0c9B64bDfF2735Ee3C932F5C408, // this is LINK / USD but it'll work fine
            usdcPriceFeed: 0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0,
            ethUsdPriceFeed: 0x0715A7794a1dc8e42615F059dD6e406A6594651A,
            functionsRouter: 0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C,
            donId: 0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000,
            subId: 1396,
            // USDC on Mumbai
            redemptionCoin: 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747
        });
        // minimumRedemptionAmount: 30e6 // Please see your brokerage for min redemption amounts
        // https://alpaca.markets/support/crypto-wallet-faq
    }

    function getAnvilEthConfig() internal view returns (NetworkConfig memory anvilNetworkConfig) {
        anvilNetworkConfig = NetworkConfig({
            tslaPriceFeed: address(tslaFeedMock),
            usdcPriceFeed: address(tslaFeedMock),
            ethUsdPriceFeed: address(ethUsdFeedMock),
            functionsRouter: address(functionsRouterMock),
            donId: 0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000, // Dummy
            subId: 1, // Dummy non-zero
            redemptionCoin: address(usdcMock)
        });
        // minimumRedemptionAmount: 30e6 // Please see your brokerage for min redemption amounts
        // https://alpaca.markets/support/crypto-wallet-faq
    }

    function _setupAnvilConfig() internal returns (NetworkConfig memory) {
        usdcMock = new MockUSDC();
        tslaFeedMock = new MockV3Aggregator(DECIAMLS, INITIAL_ANSWER);
        ethUsdFeedMock = new MockV3Aggregator(DECIAMLS, INITIAL_ANSWER);
        usdcFeedMock = new MockV3Aggregator(DECIAMLS, INITIAL_ANSWER_USD);
        functionsRouterMock = new MockFunctionsRouter();
        return getAnvilEthConfig();
    }
}
