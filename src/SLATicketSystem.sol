// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SLAAccessControl.sol";
import "./SLAContractInterface.sol";

contract SLATicketSystem {
    SLAAccessControl accessControl;
    SLAContractInterface slaContract;

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
}