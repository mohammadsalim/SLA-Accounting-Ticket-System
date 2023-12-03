// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SLAContractInterface {
    function isCompliant(uint256 severity, uint256 timestamp, uint256 validationTimestamp) external view returns (bool);
}