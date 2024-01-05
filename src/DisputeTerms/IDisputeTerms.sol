// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDisputeTerms {
    function getEscalatedSeverity(uint256 currentSeverity) external view returns (uint256);
}
