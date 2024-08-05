// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IConfigs {
    event BaseGasSet(uint256 baseGas);

    event ProtocolFeeSet(uint256 protocolFee);

    event FeeReceiverSet(address feeReceiver);

    event ExecutorAdded(address executor);

    event ExecutorRemoved(address executor);

    function executors(address executor) external view returns (bool);

    function baseGas() external view returns (uint256);

    function protocolFee() external view returns (uint256);

    function feeReceiver() external view returns (address);

    function setBaseGas(uint256 _baseGas) external;

    function setProtocolFee(uint256 _protocolFee) external;

    function setFeeReceiver(address _feeReceiver) external;

    function addExecutor(address _executor) external;

    function removeExecutor(address _executor) external;
}
