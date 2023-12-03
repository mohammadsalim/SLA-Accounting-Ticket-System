// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SLAAccessControl.sol";
import "./SLAContractInterface.sol";

contract SLATicketSystem {
    SLAAccessControl accessControl;
    SLAContractInterface slaContract;
}