// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "../src/CommonPot.sol";

// on maintnet
contract DeployCommonPot is Script {
    function run() external {
        vm.startBroadcast();

        new CommonPot(3, 4, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        vm.stopBroadcast();
    }
}
