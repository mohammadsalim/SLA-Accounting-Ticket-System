// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SLAContractInterface {
    function checkSLATerms(uint256 ticketTimestamp) external view returns (bool);
}