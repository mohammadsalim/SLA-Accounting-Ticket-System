// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SLATicketSystem.sol";
import "../src/SLAAccessControl.sol";
import "../src/SLAs/SLAContract.sol";
import "../src/SLAUpgradeableProxy.sol";
import "../src/Credits/SLACreditsToken.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy SLAAccessControl
        SLAAccessControl accessControl = new SLAAccessControl();

        // Deploy SLAContract
        SLAContract slaContract = new SLAContract();

        // Deploy SLACreditsToken with initial supply
        SLACreditsToken creditsToken = new SLACreditsToken(1e18); // 1 token with 18 decimals

        // Deploy SLATicketSystem
        SLATicketSystem ticketSystem = new SLATicketSystem(address(creditsToken), address(accessControl), address(slaContract));

        vm.stopBroadcast();
    }
}
