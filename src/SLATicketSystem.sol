// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./SLAAccessControl.sol";
import "./SLAContractInterface.sol";

contract SLATicketSystem {
    SLAAccessControl accessControl;
    SLAContractInterface slaContract;
    IERC20 public creditToken;

    /////////////////////////////////////////////////////////////////////////
    // Structs
    /////////////////////////////////////////////////////////////////////////

    // Struct for a submitted trouble ticket
    struct TroubleTicket {
        uint256 serviceIdentifier;
        string issueDescription;
        uint256 timestamp;
        address buyer;
        bool isValidated;
        string sellerComments;
        uint256 validationTimestamp;
    }

    // Struct for performance metrics
    struct PerformanceMetrics {
        uint256 totalResolvedTickets;
        uint256 totalResolutionTime;
    }

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////
    
    // Mapping of tickets
    mapping(uint256 => TroubleTicket) public tickets;
    uint256 public nextTicketId;

    // Mapping of disputes
    mapping(uint256 => bool) public disputes;

    // Variable for performance metrics
    PerformanceMetrics public metrics;

    /////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////

    event TicketSubmitted(uint256 ticketId, address buyer);
    event TicketValidated(uint256 ticketId, address seller);

    event DisputeRaised(uint256 ticketId, address buyer);
    event DisputeResolved(uint256 ticketId, address seller);

    event SLACheckPassed(uint256 ticketId, bool eligibleForCredit);

    /////////////////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////////////////

    constructor(address _creditTokenAddress, address _accessControlAddress, address _slaContractAddress) {
        creditToken = IERC20(_creditTokenAddress);
        accessControl = SLAAccessControl(_accessControlAddress);
        slaContract = SLAContractInterface(_slaContractAddress);
    }

    /////////////////////////////////////////////////////////////////////////
    // Functions
    /////////////////////////////////////////////////////////////////////////

    // Function to submit a trouble ticket
    function submitTicket(uint256 serviceIdentifier, string memory issueDescription) external {
        require(accessControl.hasRole(accessControl.BUYER_ROLE(), msg.sender), "Not a buyer");

        uint256 ticketId = nextTicketId++;
        tickets[ticketId] = TroubleTicket({
            serviceIdentifier: serviceIdentifier,
            issueDescription: issueDescription,
            timestamp: block.timestamp,
            buyer: msg.sender,
            isValidated: false,
            sellerComments: "",
            validationTimestamp: 0
        });

        emit TicketSubmitted(ticketId, msg.sender);
    }

    // Function for a seller to validate a ticket
    function validateTicket(uint256 ticketId, string memory comments) external {
        require(accessControl.hasRole(accessControl.SELLER_ROLE(), msg.sender), "Not a seller");
        TroubleTicket storage ticket = tickets[ticketId];
        require(ticket.buyer != address(0), "Ticket does not exist");
        require(!ticket.isValidated, "Ticket already validated");

        ticket.isValidated = true;
        ticket.sellerComments = comments;
        ticket.validationTimestamp = block.timestamp;

        emit TicketValidated(ticketId, msg.sender);

        // Call automated payout
        automatedPayout(ticketId);

        // Update performance metrics
        metrics.totalResolvedTickets++;
        metrics.totalResolutionTime += (block.timestamp - tickets[ticketId].timestamp);
    }

    // Function for automated payout
    function automatedPayout(uint256 ticketId) internal {
        TroubleTicket storage ticket = tickets[ticketId];
        require(ticket.isValidated, "Ticket not validated");

        bool eligibleForCredit = slaContract.checkSLATerms(ticket.timestamp);

        emit SLACheckPassed(ticketId, eligibleForCredit);

        if (eligibleForCredit) {
            uint256 creditAmount = calculateCreditAmount(ticketId);
            creditToken.transfer(ticket.buyer, creditAmount);
        }
    }

    // Function to calculate credit amount
    function calculateCreditAmount(uint256 ticketId) internal view returns (uint256) {
        // Logic to calculate the amount of credit for the ticket
        return 50; // Placeholder value
    }

    // Function for buyers to raise a dispute 
    function raiseDispute(uint256 ticketId) external {
        require(tickets[ticketId].buyer == msg.sender, "Not the ticket buyer");
        require(!disputes[ticketId], "Dispute already raised");

        disputes[ticketId] = true;
        emit DisputeRaised(ticketId, msg.sender);
    }

    // Function for sellers to resolve a dispute
    function resolveDispute(uint256 ticketId) external {
        require(accessControl.hasRole(accessControl.SELLER_ROLE(), msg.sender), "Not a seller");
        require(disputes[ticketId], "No dispute raised");

        disputes[ticketId] = false;
        emit DisputeResolved(ticketId, msg.sender);
    }

    // Function to get average resolution time for performance metrics
    function getAverageResolutionTime() external view returns (uint256) {
        return metrics.totalResolvedTickets == 0 ? 0 : metrics.totalResolutionTime / metrics.totalResolvedTickets;
    }
}