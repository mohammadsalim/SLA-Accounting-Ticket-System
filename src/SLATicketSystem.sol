// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./SLAAccessControl.sol";
import "./SLAContractInterface.sol";

contract SLATicketSystem is Initializable {
    SLAAccessControl accessControl;
    SLAContractInterface slaContract;
    IERC20 public creditToken;

    /////////////////////////////////////////////////////////////////////////
    // Structs
    /////////////////////////////////////////////////////////////////////////

    // Struct for a submitted trouble ticket
    struct TroubleTicket {
        TicketDetails details;
        TicketDispute dispute;
    }

    // Struct for the trouble ticket details
    struct TicketDetails {
        uint256 serviceIdentifier;
        string issueDescription;
        uint256 timestamp;
        address buyer;
        bool isValidated;
        string sellerComments;
        uint256 validationTimestamp;
        uint256 severity;  // Severity of the issue, e.g., 1 for low, 2 for medium, 3 for high
        bool isPriorityCustomer;  // Indicates if the buyer is a priority customer
    }

    // Struct for the details of a trouble ticket dispute
    struct TicketDispute {
        DisputeStatus disputeStatus;
        string sellerProposal;
        uint256 disputeSeverity;
    }

    // Struct for performance metrics
    struct PerformanceMetrics {
        uint256 totalTicketsRaised;
        uint256 totalResolvedTickets;
        uint256 totalResolutionTime;
        uint256 totalDisputesRaised;
        uint256 totalDisputesResolved;
        uint256 totalDisputeResolutionTime;
        uint256 averageResolutionTime;
        uint256 averageDisputeResolutionTime;
    }


    // Struct to store history of payouts
    struct PayoutHistory {
        uint256 amount;
        uint256 timestamp;
    }

    /////////////////////////////////////////////////////////////////////////
    // Enums
    /////////////////////////////////////////////////////////////////////////

    enum DisputeStatus { NoDispute, Raised, ProposalMade, Resolved }

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

    // Mapping of payout history
    mapping(uint256 => PayoutHistory) public payoutHistories;

    /////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////

    event TicketSubmitted(uint256 ticketId, address buyer);
    event TicketValidated(uint256 ticketId, address seller, bool slaCompliant);

    event DisputeRaised(uint256 ticketId, address buyer);
    event ProposalSubmitted(uint256 ticketId, string proposal);
    event DisputeResolved(uint256 ticketId, address seller);

    event SLACheckPassed(uint256 ticketId, bool eligibleForCredit);
    event CreditPayout(uint256 ticketId, address recipient, uint256 amount);

    /////////////////////////////////////////////////////////////////////////
    // Initializer
    /////////////////////////////////////////////////////////////////////////

    function initialize(
        address _creditTokenAddress, 
        address _accessControlAddress, 
        address _slaContractAddress
    ) public initializer {
        creditToken = IERC20(_creditTokenAddress);
        accessControl = SLAAccessControl(_accessControlAddress);
        slaContract = SLAContractInterface(_slaContractAddress);
    }

    /////////////////////////////////////////////////////////////////////////
    // Functions
    /////////////////////////////////////////////////////////////////////////

    // Function to submit a trouble ticket
    function submitTicket(
        uint256 serviceIdentifier,
        string memory issueDescription,
        uint256 severity,
        bool isPriorityCustomer
    ) external {
        require(accessControl.hasRole(accessControl.BUYER_ROLE(), msg.sender), "Not a buyer");

        uint256 ticketId = nextTicketId++;
        tickets[ticketId] = TroubleTicket({
            details: TicketDetails({
                serviceIdentifier: serviceIdentifier,
                issueDescription: issueDescription,
                timestamp: block.timestamp,
                buyer: msg.sender,
                isValidated: false,
                sellerComments: "",
                validationTimestamp: 0,
                severity: severity,
                isPriorityCustomer: isPriorityCustomer
            }),
            dispute: TicketDispute({
                disputeStatus: DisputeStatus.NoDispute,
                sellerProposal: "",
                disputeSeverity: 0
            })
        });

        emit TicketSubmitted(ticketId, msg.sender);

        // Update performance metrics
        metrics.totalTicketsRaised++;
    }

    // Function for a seller to validate a ticket
    function validateTicket(uint256 ticketId, string memory comments) external {
        require(accessControl.hasRole(accessControl.SELLER_ROLE(), msg.sender), "Not a seller");
        TroubleTicket storage ticket = tickets[ticketId];
        require(ticket.details.buyer != address(0), "Ticket does not exist");
        require(!ticket.details.isValidated, "Ticket already validated");

        ticket.details.isValidated = true;
        ticket.details.sellerComments = comments;
        ticket.details.validationTimestamp = block.timestamp;

        bool slaCompliant = slaContract.isCompliant(ticket.details.severity, ticket.details.timestamp, ticket.details.validationTimestamp);
        emit TicketValidated(ticketId, msg.sender, slaCompliant);

        // Call automated payout
        automatedPayout(ticketId);

        // Update performance metrics
        metrics.totalResolvedTickets++;
        metrics.totalResolutionTime += (block.timestamp - tickets[ticketId].details.timestamp);
        metrics.averageResolutionTime = metrics.totalResolvedTickets == 0 ? 0 : metrics.totalResolutionTime / metrics.totalResolvedTickets;
    }

    // Function for automated payout
    function automatedPayout(uint256 ticketId) internal {
        TroubleTicket storage ticket = tickets[ticketId];
        require(ticket.details.isValidated, "Ticket not validated");

        bool eligibleForCredit = slaContract.isCompliant(
            ticket.details.severity, ticket.details.timestamp, ticket.details.validationTimestamp
        );

        emit SLACheckPassed(ticketId, eligibleForCredit);

        if (eligibleForCredit) {
            uint256 creditAmount = calculateCreditAmount(ticketId);
            creditToken.transfer(ticket.details.buyer, creditAmount);
            recordPayoutHistory(ticketId, creditAmount);

            emit CreditPayout(ticketId, ticket.details.buyer, creditAmount);
        }
    }

    // Function to record payout history
    function recordPayoutHistory(uint256 ticketId, uint256 amount) internal {
        payoutHistories[ticketId] = PayoutHistory({
            amount: amount,
            timestamp: block.timestamp
        });
    }

    // Function to calculate credit amount
    function calculateCreditAmount(uint256 ticketId) internal view returns (uint256) {
        TroubleTicket storage ticket = tickets[ticketId];

        uint256 baseCredit = 10;  // Base credit amount
        uint256 severityFactor = ticket.details.severity * 5;  // Additional credits for severity
        uint256 timeFactor = (block.timestamp - ticket.details.timestamp) / 1 hours;  // Time factor in hours

        // Reduce credits for delays (1 credit reduced per hour of delay)
        uint256 delayPenalty = timeFactor > 24 ? (timeFactor - 24) : 0;

        // Bonus credits for priority customers
        uint256 priorityBonus = ticket.details.isPriorityCustomer ? 10 : 0;

        // Calculate total credit amount
        uint256 totalCredit = baseCredit + severityFactor + priorityBonus - delayPenalty;
    
        return totalCredit > 0 ? totalCredit : 0;  // Ensure credit is not negative
    }

    // Function for buyers to raise a dispute 
    function raiseDispute(uint256 ticketId) external {
        require(tickets[ticketId].details.buyer == msg.sender, "Not the ticket buyer");
        require(tickets[ticketId].dispute.disputeStatus == DisputeStatus.NoDispute, "Dispute already raised");
        tickets[ticketId].dispute.disputeStatus = DisputeStatus.Raised;
        emit DisputeRaised(ticketId, msg.sender);
    }

    function submitProposal(uint256 ticketId, string memory proposal) external {
        require(accessControl.hasRole(accessControl.SELLER_ROLE(), msg.sender), "Not a seller");
        require(tickets[ticketId].dispute.disputeStatus == DisputeStatus.Raised, "No dispute raised");
        tickets[ticketId].dispute.sellerProposal = proposal;
        tickets[ticketId].dispute.disputeStatus = DisputeStatus.ProposalMade;
        emit ProposalSubmitted(ticketId, proposal);
    }


    // Function for sellers to resolve a dispute
    function resolveDispute(uint256 ticketId) external {
        require(accessControl.hasRole(accessControl.SELLER_ROLE(), msg.sender), "Not a seller");
        require(disputes[ticketId], "No dispute raised");

        disputes[ticketId] = false;
        emit DisputeResolved(ticketId, msg.sender);

        // Update performance metrics
        metrics.totalDisputesResolved++;
        metrics.totalDisputeResolutionTime += (block.timestamp - tickets[ticketId].details.timestamp);
        metrics.averageDisputeResolutionTime = metrics.totalDisputesResolved == 0 ? 0 : metrics.totalDisputeResolutionTime / metrics.totalDisputesResolved;
    }

    // Function to get performance metrics
    function getPerformanceMetrics() external view returns (PerformanceMetrics memory) {
        return metrics;
    }
}