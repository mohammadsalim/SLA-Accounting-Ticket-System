// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SLAContract {
    // EXAMPLE SLA TERMS
    mapping(uint256 => uint256) public maxResolutionTimes; // Maps severity level to max resolution time in hours

    constructor() {
        // Define default SLA terms
        maxResolutionTimes[1] = 72; // Max 72 hours for low severity
        maxResolutionTimes[2] = 48; // Max 48 hours for medium severity
        maxResolutionTimes[3] = 24; // Max 24 hours for high severity
    }

    // Function to check SLA compliance based on severity and resolution time
    function isCompliant(uint256 severity, uint256 timestamp, uint256 validationTimestamp) external view returns (bool) {
        uint256 allowedTime = maxResolutionTimes[severity] * 1 hours;
        return validationTimestamp - timestamp <= allowedTime;
    }
}