// This a hackthon lol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { DeployDTsla, dTSLA } from "../script/DeployDTsla.s.sol";
import { MockFunctionsRouter } from "../src/test/mocks/MockFunctionsRouter.sol";

abstract contract Base_Test is Test {
    DeployDTsla public deployDTsla;
    address public nonOwner = makeAddr("nonOwner");
    uint256 public constant STARTING_PORTFOLIO_BALANCE = 100_000e18;

    dTSLA public dtsla;
    MockFunctionsRouter public mockFunctionsRouter;

    function setUp() public virtual {
        deployDTsla = new DeployDTsla();

        (uint64 subId, string memory source, address functionsRouter, bytes32 donId, address tslaFeed) =
            deployDTsla.getdTslaRequirements();
        mockFunctionsRouter = MockFunctionsRouter(functionsRouter);
        dtsla = deployDTsla.deployDTSLA(subId, source, functionsRouter, donId, tslaFeed);
    }

    function testCanSendMintRequestWithTslaBalance() public {
        uint256 amountToRequest = 0;

        vm.prank(dtsla.owner());
        bytes32 requestId = dtsla.sendMintRequest(amountToRequest);
        assert(requestId != 0);
    }

    function testNonOwnerCannotSendMintRequest() public {
        uint256 amountToRequest = 0;

        vm.prank(nonOwner);
        vm.expectRevert();
        dtsla.sendMintRequest(amountToRequest);
    }

    function testMintFailsWithoutInitialBalance() public {
        uint256 amountToRequest = 1e18;

        vm.prank(dtsla.owner());
        vm.expectRevert(dTSLA.dTSLA__NotEnoughCollateral.selector);
        dtsla.sendMintRequest(amountToRequest);
    }

    function testOracleCanUpdatePortfolio() public {
        uint256 amountToRequest = 0;

        vm.prank(dtsla.owner());
        bytes32 requestId = dtsla.sendMintRequest(amountToRequest);

        mockFunctionsRouter.handleOracleFulfillment(
            address(dtsla), requestId, abi.encodePacked(STARTING_PORTFOLIO_BALANCE), hex""
        );
        assert(dtsla.getPortfolioBalance() == STARTING_PORTFOLIO_BALANCE);
    }

    modifier balanceInitialized() {
        uint256 amountToRequest = 0;

        vm.prank(dtsla.owner());
        bytes32 requestId = dtsla.sendMintRequest(amountToRequest);

        mockFunctionsRouter.handleOracleFulfillment(
            address(dtsla), requestId, abi.encodePacked(STARTING_PORTFOLIO_BALANCE), hex""
        );
        _;
    }

    function testCanMintAfterPortfolioBalanceIsSet() public balanceInitialized {
        uint256 amountToRequest = 1e18; // 1 token please

        vm.prank(dtsla.owner());
        bytes32 requestId = dtsla.sendMintRequest(amountToRequest);

        mockFunctionsRouter.handleOracleFulfillment(
            address(dtsla), requestId, abi.encodePacked(STARTING_PORTFOLIO_BALANCE), hex""
        );

        assert(dtsla.totalSupply() == amountToRequest);
    }
}
