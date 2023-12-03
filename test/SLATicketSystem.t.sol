// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SLATicketSystem.sol";
import "../src/SLAAccessControl.sol";
import "../src/Credits/SLACreditsToken.sol";
import "../src/SLAs/SLAContract.sol";

contract SLATicketSystemTest is Test {
    SLATicketSystem ticketSystem;
    SLAAccessControl accessControl;
    SLACreditsToken creditsToken;
    SLAContract slaContract;

    address admin;
    address buyer;
    address seller;

    function setUp() public {
        admin = address(this);  // Test contract is the admin
        buyer = address(0x1);
        seller = address(0x2);

        accessControl = new SLAAccessControl();
        slaContract = new SLAContract();
        creditsToken = new SLACreditsToken(1e18); // 1 token with 18 decimals

        accessControl.grantRole(accessControl.BUYER_ROLE(), buyer);
        accessControl.grantRole(accessControl.SELLER_ROLE(), seller);

        ticketSystem = new SLATicketSystem(address(creditsToken), address(accessControl), address(slaContract));
    }

    // ... Write your test cases here ...
}
