// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ICopyWallet} from "./ICopyWallet.sol";

interface IEvents {
    error OnlyCopyWallets();

    function factory() external view returns (address);

    function emitDeposit(address user, uint256 amount) external;

    event Deposit(
        address indexed user,
        address indexed copyWallet,
        uint256 amount
    );

    function emitWithdraw(address user, uint256 amount) external;

    event Withdraw(
        address indexed user,
        address indexed copyWallet,
        uint256 amount
    );

    function emitEthWithdraw(address user, uint256 amount) external;

    event EthWithdraw(
        address indexed user,
        address indexed copyWallet,
        uint256 amount
    );

    function emitChargeExecutorFee(
        address executor,
        address receiver,
        uint256 fee,
        uint256 feeUsd
    ) external;

    event ChargeExecutorFee(
        address indexed executor,
        address indexed receiver,
        address indexed copyWallet,
        uint256 fee,
        uint256 feeUsd
    );

    function emitChargeProtocolFee(
        address receiver,
        uint256 sizeUsd,
        uint256 feeUsd
    ) external;

    event ChargeProtocolFee(
        address indexed receiver,
        address indexed copyWallet,
        uint256 sizeUsd,
        uint256 feeUsd
    );

    function emitCreateOrder(
        uint256 positionId,
        address source,
        uint256 lastSizeUsd,
        uint256 sizeDeltaUsd,
        bool isIncrease,
        uint256 feeUsd
    ) external;

    event CreateOrder(
        address indexed copyWallet,
        uint256 indexed positionId,
        address indexed source,
        uint256 lastSizeUsd,
        uint256 sizeDeltaUsd,
        bool isIncrease,
        uint256 feeUsd
    );

    function emitCreateGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        ICopyWallet.TaskCommand command,
        address source,
        uint256 market,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice,
        address referrer
    ) external;

    event CreateGelatoTask(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        ICopyWallet.TaskCommand command,
        address source,
        uint256 market,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice,
        address referrer
    );

    function emitUpdateGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice
    ) external;

    event UpdateGelatoTask(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice
    );

    function emitCancelGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        bytes32 reason
    ) external;

    event CancelGelatoTask(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        bytes32 reason
    );

    function emitGelatoTaskRunned(
        uint256 taskId,
        bytes32 gelatoTaskId,
        uint256 fillPrice,
        uint256 fee
    ) external;

    event GelatoTaskRunned(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        uint256 fillPrice,
        uint256 fee
    );
}
