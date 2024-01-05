// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DisputeTermsContract {
    // We define the escalation rules here
    // Example: Escalate severity after each rejection
    function getEscalatedSeverity(uint256 currentSeverity) external pure returns (uint256) {
        // Example escalation logic
        return currentSeverity + 1;
    }

    // Additional functions to manage dispute terms to be added here
}
