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

        // Deploy dependent contracts
        SLAAccessControl accessControl = new SLAAccessControl();
        SLAContract slaContract = new SLAContract();
        SLACreditsToken creditsToken = new SLACreditsToken(1e18);

        // Deploy SLATicketSystem as implementation contract
        SLATicketSystem implementation = new SLATicketSystem();

        // Prepare initializer function call
        bytes memory initData = abi.encodeWithSelector(
            SLATicketSystem.initialize.selector,
            address(creditsToken),
            address(accessControl),
            address(slaContract)
        );

        // Deploy the proxy
        address admin = msg.sender;
        SLAUpgradeableProxy proxy = new SLAUpgradeableProxy(
            address(implementation),
            admin,
            initData
        );

        // Create an instance of SLATicketSystem pointing to the proxy
        SLATicketSystem ticketSystem = SLATicketSystem(address(proxy));

        vm.stopBroadcast();
    }
}