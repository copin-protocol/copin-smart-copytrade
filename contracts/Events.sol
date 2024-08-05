// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ICopyWallet, IEvents} from "./interfaces/IEvents.sol";
import {IFactory} from "./interfaces/IFactory.sol";

contract Events is IEvents {
    /* ========== STATE ========== */

    address public immutable factory;

    /* ========== MODIFIER ========== */

    modifier onlyCopyWallets() {
        if (!IFactory(factory).accounts(msg.sender)) {
            revert OnlyCopyWallets();
        }
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _factory) {
        factory = _factory;
    }

    /* ========== EMIT ========== */

    function emitDeposit(
        address user,
        uint256 amount
    ) external override onlyCopyWallets {
        emit Deposit({user: user, copyWallet: msg.sender, amount: amount});
    }

    function emitWithdraw(
        address user,
        uint256 amount
    ) external override onlyCopyWallets {
        emit Withdraw({user: user, copyWallet: msg.sender, amount: amount});
    }

    function emitEthWithdraw(
        address user,
        uint256 amount
    ) external override onlyCopyWallets {
        emit EthWithdraw({user: user, copyWallet: msg.sender, amount: amount});
    }

    function emitChargeExecutorFee(
        address executor,
        address receiver,
        uint256 fee,
        uint256 feeUsd
    ) external override onlyCopyWallets {
        emit ChargeExecutorFee({
            executor: executor,
            receiver: receiver,
            copyWallet: msg.sender,
            fee: fee,
            feeUsd: feeUsd
        });
    }

    function emitChargeProtocolFee(
        address receiver,
        uint256 sizeUsd,
        uint256 feeUsd
    ) external override onlyCopyWallets {
        emit ChargeProtocolFee({
            receiver: receiver,
            copyWallet: msg.sender,
            sizeUsd: sizeUsd,
            feeUsd: feeUsd
        });
    }

    function emitCreateOrder(
        uint256 positionId,
        address source,
        uint256 lastSizeUsd,
        uint256 sizeDeltaUsd,
        bool isIncrease,
        uint256 feeUsd
    ) external override onlyCopyWallets {
        emit CreateOrder({
            copyWallet: msg.sender,
            positionId: positionId,
            source: source,
            lastSizeUsd: lastSizeUsd,
            sizeDeltaUsd: sizeDeltaUsd,
            isIncrease: isIncrease,
            feeUsd: feeUsd
        });
    }

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
    ) external override onlyCopyWallets {
        emit CreateGelatoTask({
            copyWallet: msg.sender,
            taskId: taskId,
            gelatoTaskId: gelatoTaskId,
            command: command,
            source: source,
            market: market,
            collateralDelta: collateralDelta,
            sizeDelta: sizeDelta,
            triggerPrice: triggerPrice,
            acceptablePrice: acceptablePrice,
            referrer: referrer
        });
    }

    function emitUpdateGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice
    ) external override onlyCopyWallets {
        emit UpdateGelatoTask({
            copyWallet: msg.sender,
            taskId: taskId,
            gelatoTaskId: gelatoTaskId,
            collateralDelta: collateralDelta,
            sizeDelta: sizeDelta,
            triggerPrice: triggerPrice,
            acceptablePrice: acceptablePrice
        });
    }

    function emitCancelGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        bytes32 reason
    ) external override onlyCopyWallets {
        emit CancelGelatoTask({
            copyWallet: msg.sender,
            taskId: taskId,
            gelatoTaskId: gelatoTaskId,
            reason: reason
        });
    }

    function emitGelatoTaskRunned(
        uint256 taskId,
        bytes32 gelatoTaskId,
        uint256 fillPrice,
        uint256 fee
    ) external override onlyCopyWallets {
        emit GelatoTaskRunned({
            copyWallet: msg.sender,
            taskId: taskId,
            gelatoTaskId: gelatoTaskId,
            fillPrice: fillPrice,
            fee: fee
        });
    }
}
