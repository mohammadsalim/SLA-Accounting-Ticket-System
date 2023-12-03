// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        admin = address(this); // Test contract is the admin
        buyer = address(0x1);
        seller = address(0x2);

        // Deploy contracts
        accessControl = new SLAAccessControl();
        slaContract = new SLAContract();
        creditsToken = new SLACreditsToken(1e18); // 1 token with 18 decimals

        // Grant roles
        accessControl.grantRole(accessControl.BUYER_ROLE(), buyer);
        accessControl.grantRole(accessControl.SELLER_ROLE(), seller);

        // Deploy SLATicketSystem
        ticketSystem = new SLATicketSystem(address(creditsToken), address(accessControl), address(slaContract));

        // Transfer tokens to SLATicketSystem
        uint256 amountToTransfer = 1e18 / 2; // Transfer half of the initial supply
        creditsToken.transfer(address(ticketSystem), amountToTransfer);
    }

    function testTicketSubmission() public {
        vm.prank(buyer);  // Set the next caller to be the buyer
        ticketSystem.submitTicket(1, "Issue Description", 1, false);

        (uint256 serviceIdentifier, , , address ticketBuyer, , , , , ) = ticketSystem.tickets(0);
        assertEq(serviceIdentifier, 1);
        assertEq(ticketBuyer, buyer);
    }

    function testTicketValidation() public {
        // Submit a ticket
        vm.prank(buyer);
        ticketSystem.submitTicket(1, "Issue Description", 1, false);

        // Validate the ticket
        vm.prank(seller);
        ticketSystem.validateTicket(0, "Resolved");

        (, , , , bool isValidated, , , , ) = ticketSystem.tickets(0);
        assertTrue(isValidated);
    }

}
