// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "src/CommonPot.sol";

import { ERC20 as ERC20OZ } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { WETH9 } from "test/mocks/WETH9.sol";

contract TestCommonPot is Test {
    CommonPot commonPot;
    address owner;
    address user1;
    WETH9 weth = new WETH9();
    ERC20OZ DAI = new ERC20OZ("DAI", "DAI");

    function setUp() public {
        // sets block.timestamp to 10 days
        // by default it is set to 1
        vm.warp(864000);

        owner = address(0xa);
        user1 = address(0xb);
        deal(user1, 100 * 10 ^ 18);

        startHoax(owner);
        commonPot = new CommonPot(1, 3, address(weth));
        // simulate user1 own 10% of the vault
        commonPot.transfer(user1, (10 * 10) ^ 18);
        assertEq(commonPot.balanceOf(user1), (10 * 10) ^ 18);
    }

    function testSetMinDaysDelayDeployment() public {
        assertEq(commonPot.minDaysDelay(), 1);
    }

    function testCannotPrepareIfLocked() public {
        vm.store(address(commonPot), bytes32(uint256(7)), bytes32(block.timestamp + 10));
        vm.expectRevert("Locked");
        commonPot.prepareLock();
    }

    function testPrepareLock() public {
        commonPot.prepareLock();
        uint256 minDaysDelayTimestamp = uint256(vm.load(address(commonPot), bytes32(uint256(8))));
        assertEq(minDaysDelayTimestamp, block.timestamp);
    }

    function testCannotSetLockIfNotPrepared() public {
        vm.store(address(commonPot), bytes32(uint256(8)), bytes32(block.timestamp + 10));
        vm.expectRevert("Lock not prepared");
        commonPot.setLock(10000);
    }

    function testSetLock() public {
        vm.store(address(commonPot), bytes32(uint256(8)), bytes32(block.timestamp - 2 days));
        commonPot.setLock(10000);
        uint256 lock = uint256(vm.load(address(commonPot), bytes32(uint256(7))));
        assertEq(lock, block.timestamp + 10000);
    }

    function testCannotAddAssetIfMaxReached() public {
        // use vm.store instead of contract function
        commonPot.addAsset(address(1));
        commonPot.addAsset(address(2));
        commonPot.addAsset(address(3));
        vm.expectRevert("Max assets reached");
        commonPot.addAsset(address(4));
    }

    function testAddAsset() public {
        commonPot.addAsset(address(1));
        assertEq(commonPot.whitelistedAsset(address(1)), true);
    }

    function testCannotAddAssetsIfMaxReached() public {
        // use vm.store instead of contract function
        commonPot.addAsset(address(1));
        commonPot.addAsset(address(2));
        commonPot.addAsset(address(3));
        address[] memory assets = new address[](2);
        assets[0] = address(1);
        assets[0] = address(2);
        vm.expectRevert("Max assets reached");
        commonPot.addAssets(assets);
    }

    function testAddAssets() public {
        address[] memory assets = new address[](2);
        assets[0] = address(1);
        assets[1] = address(2);
        commonPot.addAssets(assets);
        assertEq(commonPot.whitelistedAsset(address(1)), true);
        assertEq(commonPot.whitelistedAsset(address(2)), true);
    }

    function testCannotWithdrawFundNotWhitelised() public {
        deal(address(DAI), address(commonPot), 100 * 10 ^ 18);
        assertEq(DAI.balanceOf(address(commonPot)), 100 * 10 ^ 18);
        vm.expectRevert("Asset not whitelisted");
        commonPot.withdrawFund(DAI, (5 * 10) ^ 18);
    }

    function testCannotWithdrawFundIfLocked() public {
        vm.store(address(commonPot), bytes32(uint256(7)), bytes32(block.timestamp + 10));
        deal(address(DAI), address(commonPot), 100 * 10 ^ 18);
        assertEq(DAI.balanceOf(address(commonPot)), 100 * 10 ^ 18);
        vm.expectRevert("Locked");
        commonPot.withdrawFund(DAI, (5 * 10) ^ 18);
    }

    function testWithdrawFund() public {
        deal(address(DAI), address(commonPot), 100 * 10 ^ 18);
        assertEq(DAI.balanceOf(address(commonPot)), 100 * 10 ^ 18);
        // use vm.store instead of contract function
        commonPot.addAsset(address(DAI));
        changePrank(user1);
        commonPot.withdrawFund(DAI, (5 * 10) ^ 18);
        assertEq(DAI.balanceOf(user1), (5 * 10) ^ 18);
    }

    function testCannotWithdrawFundsNotWhitelised() public {
        deal(address(DAI), address(commonPot), 100 * 10 ^ 18);
        assertEq(DAI.balanceOf(address(commonPot)), 100 * 10 ^ 18);
        IERC20[] memory assets = new IERC20[](2);
        assets[0] = DAI;
        assets[1] = IERC20(address(weth));
        changePrank(user1);
        vm.expectRevert("Asset not whitelisted");
        commonPot.withdrawFunds(assets, (5 * 10) ^ 18);
    }

    function testCannotWithdrawFundsIfLocked() public {
        vm.store(address(commonPot), bytes32(uint256(7)), bytes32(block.timestamp + 10));
        deal(address(DAI), address(commonPot), 100_000_000);
        assertEq(DAI.balanceOf(address(commonPot)), 100_000_000);
        IERC20[] memory assets = new IERC20[](2);
        assets[0] = DAI;
        assets[1] = IERC20(address(weth));
        changePrank(user1);
        vm.expectRevert("Locked");
        commonPot.withdrawFunds(assets, (5 * 10) ^ 18);
    }

    function testWithdrawFunds() public {
        deal(address(DAI), address(commonPot), 100 * 10 ^ 18);
        deal(address(weth), address(commonPot), 100 * 10 ^ 18);
        // use vm.store instead of contract function
        commonPot.addAsset(address(DAI));
        commonPot.addAsset(address(weth));
        assertEq(DAI.balanceOf(address(commonPot)), 100 * 10 ^ 18);
        assertEq(weth.balanceOf(address(commonPot)), 100 * 10 ^ 18);
        IERC20[] memory assets = new IERC20[](2);
        assets[0] = DAI;
        assets[1] = IERC20(address(weth));
        changePrank(user1);
        commonPot.withdrawFunds(assets, (5 * 10) ^ 18);
        assertEq(DAI.balanceOf(user1), (5 * 10) ^ 18);
        assertEq(weth.balanceOf(user1), (5 * 10) ^ 18);
    }

    function testReceive() public {
        (bool success, ) = address(commonPot).call{ value: 100 }("");
        assertEq(success, true);
        assertEq(weth.balanceOf(address(commonPot)), 100);
    }
}
