// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ICopyWallet {
    enum Command {
        OWNER_MODIFY_FUND, //0
        OWNER_WITHDRAW_ETH, //1
        OWNER_WITHDRAW_TOKEN, //2
        PERP_CREATE_ACCOUNT, //3
        PERP_MODIFY_COLLATERAL, //4
        PERP_PLACE_ORDER, //5
        PERP_CLOSE_ORDER, //6
        PERP_CANCEL_ORDER, //7
        PERP_WITHDRAW_ALL_MARGIN, //8
        GELATO_CREATE_TASK, //9
        GELATO_UPDATE_TASK, //10
        GELETO_CANCEL_TASK, //11
        PERP_UPDATE_SLTP //12
    }

    enum TaskCommand {
        STOP_ORDER, //0
        LIMIT_ORDER //1
    }

    struct CopyWalletConstructorParams {
        address factory;
        address events;
        address configs;
        address usdAsset;
        address automate;
        address taskCreator;
    }

    struct Position {
        address source;
        uint256 lastSizeUsd;
        uint256 lastSizeDeltaUsd;
        uint256 lastFeeUsd;
    }

    struct Task {
        bytes32 gelatoTaskId;
        TaskCommand command;
        address source;
        uint256 market;
        int256 collateralDelta;
        int256 sizeDelta;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        address referrer;
    }

    error LengthMismatch();

    error InvalidCommandType(uint256 commandType);

    error ZeroSizeDelta();

    error InsufficientAvailableFund(uint256 available, uint256 required);

    error EthWithdrawalFailed();

    error NoOpenPosition();

    error NoOrderFound();

    error NoTaskFound();

    error SourceMismatch();

    error PositionExist();

    error CannotExecuteTask(uint256 taskId, address executor);

    function VERSION() external view returns (bytes32);

    function executor() external view returns (address);

    function lockedFund() external view returns (uint256);

    function lockedFundD18() external view returns (uint256);

    function availableFund() external view returns (uint256);

    function availableFundD18() external view returns (uint256);

    function ethToUsd(uint256 _amount) external view returns (uint256);

    // TODO enable again
    // function checker(
    //     uint256 _taskId
    // ) external view returns (bool canExec, bytes memory execPayload);
    // function getTask(uint256 _taskId) external view returns (Task memory);
    // function executeTask(uint256 _taskId) external;

    function positions(uint256 _key) external view returns (Position memory);

    function init(address _owner, address _executor) external;

    function execute(
        Command[] calldata _commands,
        bytes[] calldata _inputs
    ) external payable;
}
