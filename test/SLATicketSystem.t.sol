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
        ticketSystem = new SLATicketSystem();
        ticketSystem.initialize(address(creditsToken), address(accessControl), address(slaContract));

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

    function testAutomatedPayout() public {
        // Set up a buyer and submit a ticket
        vm.startPrank(buyer);
        ticketSystem.submitTicket(1, "Issue Description", 1, false);
        vm.stopPrank();

        // Get buyer's balance before payout
        uint256 initialBuyerBalance = creditsToken.balanceOf(buyer);

        // Validate the ticket as a seller, triggering an automated payout
        vm.startPrank(seller);
        ticketSystem.validateTicket(0, "Resolved");
        vm.stopPrank();

        // Get buyer's balance after payout
        uint256 newBuyerBalance = creditsToken.balanceOf(buyer);

        // Calculate the expected payout amount based on your contract logic
        uint256 expectedPayout = calculateExpectedPayout(1, 1, false); // Adjust parameters as per your test setup

        // The buyer's balance should have increased by the expected payout amount
        assertEq(newBuyerBalance, initialBuyerBalance + expectedPayout, "Buyer did not receive the correct payout amount");
    }

    // the calculateCreditAmount function in the SLATicketSystem contract is marked as internal
    function calculateExpectedPayout(uint256 severity, uint256 timestamp, bool isPriorityCustomer) internal pure returns (uint256) {
        uint256 baseCredit = 10;  // Base credit amount
        uint256 severityFactor = severity * 5;  // Additional credits for severity
        // Time factor calculation needs to be adapted based on your contract logic and test setup
        uint256 delayPenalty = 0; // Assuming no delay in this test case

        uint256 priorityBonus = isPriorityCustomer ? 10 : 0;

        // Calculate total credit amount
        uint256 totalCredit = baseCredit + severityFactor + priorityBonus - delayPenalty;

        return totalCredit > 0 ? totalCredit : 0;  // Ensure credit is not negative
    }

    function testDisputeResolution() public {
        // Submit and validate a ticket
        vm.prank(buyer);
        ticketSystem.submitTicket(1, "Issue Description", 1, false);

        vm.prank(seller);
        ticketSystem.validateTicket(0, "Resolved");

        // Raise a dispute
        vm.prank(buyer);
        ticketSystem.raiseDispute(0);
        bool isDisputed = ticketSystem.disputes(0);
        assertTrue(isDisputed);

        // Resolve the dispute
        vm.prank(seller);
        ticketSystem.resolveDispute(0);
        isDisputed = ticketSystem.disputes(0);
        assertFalse(isDisputed);
    }

    function testPerformanceMetricsUpdate() public {
        // Initial metrics should be zero
        SLATicketSystem.PerformanceMetrics memory initialMetrics = ticketSystem.getPerformanceMetrics();
        assertEq(initialMetrics.totalTicketsRaised, 0);

        // Submit a ticket
        vm.prank(buyer);
        ticketSystem.submitTicket(1, "Issue Description", 1, false);

        // Metrics should be updated
        SLATicketSystem.PerformanceMetrics memory updatedMetrics = ticketSystem.getPerformanceMetrics();
        assertEq(updatedMetrics.totalTicketsRaised, 1);
    }
}
