// This a hackthon lol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { DeploySTsla, sTSLA } from "../../script/DeploySTsla.s.sol";
import { MockUSDC } from "../../src/test/mocks/MockUSDC.sol";

contract sTSLATest is Test {
    DeploySTsla public deploySTsla;
    address public user = makeAddr("user");
    sTSLA public stsla;
    uint256 constant STARTING_ETH_BALANCE = 100e18;

    function setUp() public {
        deploySTsla = new DeploySTsla();
        (address tslaFeed, address ethFeed) = deploySTsla.getdTslaRequirements();
        stsla = deploySTsla.deploySTSLA(tslaFeed, ethFeed);
    }

    function testCanMintSTsla() public {
        vm.deal(user, STARTING_ETH_BALANCE);
        vm.prank(user);
        stsla.depositAndmint{ value: 10e18 }(1e18);

        assertEq(stsla.balanceOf(user), 1e18);
    }

    function testCanRedeem() public {
        vm.deal(user, STARTING_ETH_BALANCE);
        vm.startPrank(user);
        stsla.depositAndmint{ value: 10e18 }(1e18);
        stsla.approve(address(stsla), 1e18);
        stsla.redeemAndBurn(1e18);
        vm.stopPrank();
        assertEq(stsla.balanceOf(user), 0);
    }
}
