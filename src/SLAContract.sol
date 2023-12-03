// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SLAContract {
    // EXAMPLE SLA TERMS; Intended to be more complex in a real-world SLA contract
    uint256 public constant MAX_RESOLUTION_TIME = 3 days;

    // Function to check if a ticket meets the SLA terms
    function checkSLATerms(uint256 ticketTimestamp) external view returns (bool) {
        return (block.timestamp - ticketTimestamp) <= MAX_RESOLUTION_TIME;
    }
}