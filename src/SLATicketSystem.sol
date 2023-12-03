// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SLAAccessControl.sol";
import "./SLAContractInterface.sol";

contract SLATicketSystem {
    SLAAccessControl accessControl;
    SLAContractInterface slaContract;

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

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////
    
    // Mapping of tickets
    mapping(uint256 => TroubleTicket) public tickets;
    uint256 public nextTicketId;

    /////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////

    event TicketSubmitted(uint256 ticketId, address buyer);
    event TicketValidated(uint256 ticketId, address seller);

    /////////////////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////////////////

    constructor(address _accessControlAddress, address _slaContractAddress) {
        accessControl = SLAAccessControl(_accessControlAddress);
        slaContract = SLAContractInterface(_slaContractAddress);
    }

    /////////////////////////////////////////////////////////////////////////
    // Functions
    /////////////////////////////////////////////////////////////////////////

    // Function to submit a trouble ticket
    function submitTicket(uint256 serviceIdentifier, string memory issueDescription) external {
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
        TroubleTicket storage ticket = tickets[ticketId];
        require(ticket.buyer != address(0), "Ticket does not exist");
        require(!ticket.isValidated, "Ticket already validated");

        ticket.isValidated = true;
        ticket.sellerComments = comments;
        ticket.validationTimestamp = block.timestamp;

        emit TicketValidated(ticketId, msg.sender);
    }
}