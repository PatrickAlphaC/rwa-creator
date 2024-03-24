// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { MockV3Aggregator } from "../src/test/mocks/MockV3Aggregator.sol";
import { MockFunctionsRouter } from "../src/test/mocks/MockFunctionsRouter.sol";

contract HelperConfig {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address tslaPriceFee;
        address ethUsdPriceFeed;
        address functionsRouter;
        bytes32 donId;
        uint64 subId;
    }

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

    // Mocks
    MockV3Aggregator public tslaFeedMock;
    MockV3Aggregator public ethUsdFeedMock;
    MockFunctionsRouter public functionsRouterMock;

    // TSLA USD & ETH USD both have 8 decimals
    uint8 public constant DECIAMLS = 8;
    int256 public constant INITIAL_ANSER = 2000e8;

    constructor() {
        chainIdToNetworkConfig[137] = getPolygonConfig();
        chainIdToNetworkConfig[80_001] = getMumbaiConfig();
        chainIdToNetworkConfig[31_337] = _setupAnvilConfig();
        activeNetworkConfig = chainIdToNetworkConfig[block.chainid];
    }

    function getPolygonConfig() internal pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            tslaPriceFee: 0x567E67f456c7453c583B6eFA6F18452cDee1F5a8,
            ethUsdPriceFeed: 0xF9680D99D6C9589e2a93a78A04A279e509205945,
            functionsRouter: 0xdc2AAF042Aeff2E68B3e8E33F19e4B9fA7C73F10,
            donId: 0x66756e2d706f6c79676f6e2d6d61696e6e65742d310000000000000000000000,
            subId: 0 // TODO
         });
    }

    function getMumbaiConfig() internal pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            tslaPriceFee: 0x1C2252aeeD50e0c9B64bDfF2735Ee3C932F5C408, // this is LINK / USD but it'll work fine
            ethUsdPriceFeed: 0x0715A7794a1dc8e42615F059dD6e406A6594651A,
            functionsRouter: 0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C,
            donId: 0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000,
            subId: 1396
        });
    }

    function getAnvilEthConfig() internal view returns (NetworkConfig memory anvilNetworkConfig) {
        anvilNetworkConfig = NetworkConfig({
            tslaPriceFee: address(tslaFeedMock),
            ethUsdPriceFeed: address(ethUsdFeedMock),
            functionsRouter: address(functionsRouterMock),
            donId: 0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000, // Dummy
            subId: 0 // Dummy
         });
    }

    function _setupAnvilConfig() internal returns (NetworkConfig memory) {
        tslaFeedMock = new MockV3Aggregator(DECIAMLS, INITIAL_ANSER);
        ethUsdFeedMock = new MockV3Aggregator(DECIAMLS, INITIAL_ANSER);
        functionsRouterMock = new MockFunctionsRouter();
        return getAnvilEthConfig();
    }
}
