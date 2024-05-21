// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IConfigs} from "./interfaces/IConfigs.sol";
import {Owned} from "./utils/Owned.sol";

contract Configs is IConfigs, Owned {
    /* ========== STATES ========== */

    uint256 public protocolFee = 4000; // 0.025%
    address public feeReceiver;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner) Owned(_owner) {
        feeReceiver = _owner;
    }

    /* ========== SETTERS ========== */

    function setProtocolFee(uint256 _protocolFee) external override onlyOwner {
        require(_protocolFee >= 1000, "Over max fee"); // maximum is 1/1000 = 0.1% trade size
        protocolFee = _protocolFee;
        emit ProtocolFeeSet(protocolFee);
    }

    function setFeeReceiver(address _feeReceiver) external override onlyOwner {
        require(_feeReceiver != address(0), "Invalid address");
        feeReceiver = _feeReceiver;
        emit FeeReceiverSet(feeReceiver);
    }
}
