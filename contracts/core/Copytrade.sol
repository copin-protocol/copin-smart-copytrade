// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ICopytrade} from "../interfaces/ICopytrade.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IConfigs} from "../interfaces/IConfigs.sol";
import {IEvents} from "../interfaces/IEvents.sol";
import {ITaskCreator} from "../interfaces/ITaskCreator.sol";
import {IERC20} from "../interfaces/token/IERC20.sol";
import {Auth} from "../utils/Auth.sol";
import {AutomateReady} from "../utils/gelato/AutomateReady.sol";
import {Module, ModuleData, IAutomate} from "../utils/gelato/Types.sol";

abstract contract Copytrade is
    ICopytrade,
    Auth,
    AutomateReady,
    ReentrancyGuard
{
    bytes32 public constant VERSION = "0.1.0";
    bytes32 internal constant TRACKING_CODE = "COPIN";

    IFactory internal immutable FACTORY;
    IEvents internal immutable EVENTS;
    IConfigs internal immutable CONFIGS;
    IERC20 internal immutable USD_ASSET; // USD token
    ITaskCreator internal immutable TASK_CREATOR;

    address public executor;
    uint256 public lockedFund;
    uint256 public taskId;
    uint128[] public accountIds;

    mapping(uint256 => Task) internal _tasks;
    mapping(bytes32 => uint128) internal _keyAccounts;
    mapping(uint128 => Order) internal _accountOrders;

    constructor(
        CopytradeConstructorParams memory _params
    ) Auth(address(0)) AutomateReady(_params.automate, _params.taskCreator) {
        FACTORY = IFactory(_params.factory);
        EVENTS = IEvents(_params.events);
        CONFIGS = IConfigs(_params.configs);
        USD_ASSET = IERC20(_params.usdAsset);
        TASK_CREATOR = ITaskCreator(_params.taskCreator);
    }

    function executorUsdFee(
        uint256 _fee
    ) public view virtual returns (uint256) {}

    function availableFund() public view override returns (uint256) {
        return USD_ASSET.balanceOf(address(this)) - lockedFund;
    }

    function getAllocatedAccount(
        address _source,
        uint256 _market
    ) public view returns (uint128) {
        bytes32 key = keccak256(abi.encodePacked(_source, _market));
        uint128 accountId = _keyAccounts[key];
        if (accountId != 0 && _accountOrders[accountId].market == _market)
            return accountId;
        for (uint i = 0; i < accountIds.length; i++) {
            uint128 iAccountId = accountIds[i];
            if (accountIdle(iAccountId)) return iAccountId;
        }
        return 0;
    }

    function getOpenPosition(
        address _source,
        uint256 _market
    ) public view returns (int256 size, int256 pnl, int256 funding) {
        bytes32 key = keccak256(abi.encodePacked(_source, _market));
        uint128 accountId = _keyAccounts[key];
        return _perpGetOpenPosition(accountId, _market);
    }

    function getOrder(
        address _source,
        uint256 _market
    ) public view returns (Order memory order) {
        bytes32 key = keccak256(abi.encodePacked(_source, _market));
        uint128 accountId = _keyAccounts[key];
        order = _accountOrders[accountId];
    }

    function accountIdle(uint128 _accountId) public view returns (bool) {
        return _perpAccountIdle(_accountId);
    }

    function accountIdleByIndex(uint256 _index) public view returns (bool) {
        uint128 accountId = accountIds[_index];
        return accountIdle(accountId);
    }

    function numOfAccounts() external view returns (uint256) {
        return accountIds.length;
    }

    function getKeyAccount(
        address _source,
        uint256 _market
    ) external view returns (uint128) {
        bytes32 key = keccak256(abi.encodePacked(_source, _market));
        return _keyAccounts[key];
    }

    function checker(
        uint256 _taskId
    ) external view returns (bool canExec, bytes memory execPayload) {
        canExec = _validTask(_taskId);

        // calldata for execute func
        execPayload = abi.encodeCall(this.executeTask, (_taskId));

        if (tx.gasprice > 200 gwei) return (false, bytes("Gas price too high"));
    }

    function getTask(
        uint256 _taskId
    ) public view override returns (Task memory) {
        return _tasks[_taskId];
    }

    function init(address _owner, address _executor) external override {
        if (msg.sender != address(FACTORY)) revert Unauthorized();
        _setInitialOwnership(_owner);
        _addInitialDelegate(_executor);
        _perpInit();
    }

    function transferOwnership(address _newOwner) public override {
        super.transferOwnership(_newOwner);
        FACTORY.updateCopytradeOwnership({
            _newOwner: _newOwner,
            _oldOwner: msg.sender
        });
    }

    function closePosition(
        uint128 _accountId,
        uint256 _market,
        uint256 _acceptablePrice
    ) external {
        if (!isAuth(msg.sender)) revert Unauthorized();
        _perpClosePosition(_accountId, _market, _acceptablePrice);
    }

    function execute(
        Command[] calldata _commands,
        bytes[] calldata _inputs
    ) external payable override nonReentrant {
        uint256 numCommands = _commands.length;
        if (_inputs.length != numCommands) {
            revert LengthMismatch();
        }
        for (uint256 commandIndex = 0; commandIndex < numCommands; ) {
            _dispatch(_commands[commandIndex], _inputs[commandIndex]);
            unchecked {
                ++commandIndex;
            }
        }
        if (msg.sender == executor) {
            _chargeExecutorFee(msg.sender, numCommands);
        }
    }

    function executeTask(
        uint256 _taskId
    ) external nonReentrant onlyDedicatedMsgSender {
        Task memory task = getTask(_taskId);
        (_taskId);

        if (!_perpValidTask(task)) {
            revert CannotExecuteTask({taskId: _taskId, executor: msg.sender});
        }

        delete _tasks[_taskId];

        ITaskCreator(TASK_CREATOR).cancelTask(task.gelatoTaskId);

        uint256 fee = _chargeExecutorFee(address(TASK_CREATOR), 1);

        _perpExecuteTask(_taskId, task);

        EVENTS.emitGelatoTaskRunned({
            taskId: _taskId,
            gelatoTaskId: task.gelatoTaskId,
            fillPrice: task.triggerPrice,
            fee: fee
        });
    }

    function _protocolFee(uint256 _size) internal view returns (uint256) {
        return _size / IConfigs(CONFIGS).protocolFee();
    }

    function _sufficientFund(int256 _amountOut, bool origin) internal view {
        /// @dev origin true => amount as fund asset decimals
        uint256 _fundOut = origin
            ? _abs(_amountOut)
            : _toUsdAsset(_abs(_amountOut));
        if (_fundOut > availableFund()) {
            revert InsufficientAvailableFund(availableFund(), _fundOut);
        }
    }

    function _allocatedAccount(
        address _source,
        uint256 _market
    ) internal view returns (uint128 accountId) {
        accountId = getAllocatedAccount(_source, _market);
        if (accountId == 0) revert NoAccountAvailable();
    }

    function _validTask(uint256 _taskId) internal view returns (bool) {
        Task memory task = getTask(_taskId);

        if (task.market == 0) {
            return false;
        }
        return _perpValidTask(task);
    }

    function _setInitialOwnership(address _owner) private {
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function _addInitialDelegate(address _executor) private {
        delegates[_executor] = true;
        emit DelegatedCopytradeAdded({caller: msg.sender, delegate: _executor});
    }

    function _dispatch(Command _command, bytes calldata _inputs) internal {
        uint256 commandIndex = uint256(_command);
        if (commandIndex < 3) {
            if (!isOwner(msg.sender)) revert Unauthorized();

            if (_command == Command.OWNER_MODIFY_FUND) {
                int256 amount;
                assembly {
                    amount := calldataload(_inputs.offset)
                }
                _modifyFund({_amount: amount, _msgSender: msg.sender});
            } else if (_command == Command.OWNER_WITHDRAW_ETH) {
                uint256 amount;
                assembly {
                    amount := calldataload(_inputs.offset)
                }
                _withdrawEth({_amount: amount, _msgSender: msg.sender});
            }
        } else {
            if (!isAuth(msg.sender)) revert Unauthorized();
            if (_command == Command.PERP_CREATE_ACCOUNT) {
                _perpCreateAccount();
            } else if (_command == Command.PERP_MODIFY_COLLATERAL) {
                _perpModifyCollateral(_inputs);
            } else if (_command == Command.PERP_PLACE_ORDER) {
                _perpPlaceOrder(_inputs);
            } else if (_command == Command.PERP_CLOSE_ORDER) {
                _perpCloseOrder(_inputs);
            } else if (_command == Command.PERP_WITHDRAW_ALL_MARGIN) {
                _perpWithdrawAllMargin(_inputs);
            } else if (_command == Command.GELATO_CREATE_TASK) {
                TaskCommand taskCommand;
                address source;
                uint256 market;
                int256 collateralDelta;
                int256 sizeDelta;
                uint256 triggerPrice;
                uint256 acceptablePrice;
                address referrer;
                assembly {
                    taskCommand := calldataload(_inputs.offset)
                    source := calldataload(add(_inputs.offset, 0x20))
                    market := calldataload(add(_inputs.offset, 0x40))
                    collateralDelta := calldataload(add(_inputs.offset, 0x60))
                    sizeDelta := calldataload(add(_inputs.offset, 0x80))
                    triggerPrice := calldataload(add(_inputs.offset, 0xa0))
                    acceptablePrice := calldataload(add(_inputs.offset, 0xc0))
                    referrer := calldataload(add(_inputs.offset, 0xe0))
                }
                _createGelatoTask({
                    _command: taskCommand,
                    _source: source,
                    _market: market,
                    _collateralDelta: collateralDelta,
                    _sizeDelta: sizeDelta,
                    _triggerPrice: triggerPrice,
                    _acceptablePrice: acceptablePrice,
                    _referrer: referrer
                });
            } else if (_command == Command.GELATO_UPDATE_TASK) {
                uint256 requestTaskId;
                int256 collateralData;
                int256 sizeDelta;
                uint256 triggerPrice;
                uint256 acceptablePrice;
                assembly {
                    requestTaskId := calldataload(_inputs.offset)
                    collateralData := calldataload(add(_inputs.offset, 0x20))
                    sizeDelta := calldataload(add(_inputs.offset, 0x40))
                    triggerPrice := calldataload(add(_inputs.offset, 0x60))
                    acceptablePrice := calldataload(add(_inputs.offset, 0x80))
                }
                _updateGelatoTask({
                    _taskId: requestTaskId,
                    _collateralDelta: collateralData,
                    _sizeDelta: sizeDelta,
                    _triggerPrice: triggerPrice,
                    _acceptablePrice: acceptablePrice
                });
            } else if (_command == Command.GELETO_CANCEL_TASK) {
                uint256 requestTaskId;
                assembly {
                    requestTaskId := calldataload(_inputs.offset)
                }
                _cancelGelatoTask(requestTaskId);
            }
            if (commandIndex > 11) {
                revert InvalidCommandType(commandIndex);
            }
        }
    }

    receive() external payable {}

    function _withdrawEth(uint256 _amount, address _msgSender) internal {
        if (_amount > 0) {
            (bool success, ) = payable(_msgSender).call{value: _amount}("");
            if (!success) revert EthWithdrawalFailed();

            EVENTS.emitEthWithdraw({user: _msgSender, amount: _amount});
        }
    }

    function _toUsdAsset(uint256 _amount) internal view returns (uint256) {
        /// @dev convert to fund asset decimals
        return (_amount * 10 ** USD_ASSET.decimals()) / 10 ** 18;
    }

    function _modifyFund(int256 _amount, address _msgSender) internal {
        /// @dev if amount is positive, deposit
        if (_amount > 0) {
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            USD_ASSET.transferFrom(_msgSender, address(this), _abs(_amount));
            EVENTS.emitDeposit({user: _msgSender, amount: _abs(_amount)});
        } else if (_amount < 0) {
            /// @dev if amount is negative, withdraw
            _sufficientFund(_amount, true);
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            USD_ASSET.transfer(_msgSender, _abs(_amount));
            EVENTS.emitWithdraw({user: _msgSender, amount: _abs(_amount)});
        }
    }

    function _chargeExecutorFee(
        address _executor,
        uint256 multiplier
    ) internal returns (uint256) {
        uint256 fee;
        if (_executor == address(TASK_CREATOR)) {
            (fee, ) = _getFeeDetails();
        } else {
            fee = CONFIGS.executorFee();
        }
        fee = fee * multiplier;
        uint256 feeUsd = executorUsdFee(fee);
        address feeReceiver = CONFIGS.feeReceiver();
        if (feeUsd <= availableFund()) {
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            USD_ASSET.transfer(feeReceiver, feeUsd);
        } else {
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            USD_ASSET.transferFrom(owner, feeReceiver, feeUsd);
        }
        EVENTS.emitChargeExecutorFee({
            executor: _executor,
            receiver: feeReceiver,
            fee: fee,
            feeUsd: feeUsd
        });
        return fee;
    }

    function _chargeProtocolFee(uint256 _sizeUsd, uint256 _feeUsd) internal {
        if (_feeUsd > availableFund()) {
            revert InsufficientAvailableFund(availableFund(), _feeUsd);
        }
        address feeReceiver = CONFIGS.feeReceiver();
        USD_ASSET.transfer(feeReceiver, _feeUsd);
        EVENTS.emitChargeProtocolFee({
            receiver: feeReceiver,
            sizeUsd: _sizeUsd,
            feeUsd: _feeUsd
        });
    }

    function _preOrder(uint256 _market, uint256 _sizeDeltaUsd) internal {}

    function _postOrder(uint256 _market, uint256 _sizeDeltaUsd) internal {
        uint256 feeUsd = _protocolFee(_sizeDeltaUsd);
        _chargeProtocolFee(_sizeDeltaUsd, feeUsd);
    }

    function _perpGetOpenPosition(
        uint128 _accountId,
        uint256 _market
    ) internal view virtual returns (int256 size, int256 pnl, int256 funding) {}

    function _perpAccountIdle(
        uint128 _accountId
    ) internal view virtual returns (bool) {}

    function _perpValidTask(
        Task memory _task
    ) internal view virtual returns (bool) {}

    function _createGelatoTask(
        TaskCommand _command,
        address _source,
        uint256 _market,
        int256 _collateralDelta,
        int256 _sizeDelta,
        uint256 _triggerPrice,
        uint256 _acceptablePrice,
        address _referrer
    ) internal {
        if (_sizeDelta == 0) revert ZeroSizeDelta();
        if (_collateralDelta > 0) {
            _sufficientFund(_collateralDelta, false);
            lockedFund += _toUsdAsset(_abs(_collateralDelta));
        }

        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });
        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;
        moduleData.args[0] = abi.encode(
            address(this),
            abi.encodeCall(this.checker, taskId)
        );

        bytes32 _gelatoTaskId = ITaskCreator(TASK_CREATOR).createTask({
            execData: abi.encodeCall(this.executeTask, taskId),
            moduleData: moduleData
        });

        _tasks[taskId] = Task({
            gelatoTaskId: _gelatoTaskId,
            command: _command,
            source: _source,
            market: _market,
            collateralDelta: _collateralDelta,
            sizeDelta: _sizeDelta,
            triggerPrice: _triggerPrice,
            acceptablePrice: _acceptablePrice,
            referrer: _referrer
        });

        EVENTS.emitCreateGelatoTask({
            taskId: taskId,
            gelatoTaskId: _gelatoTaskId,
            command: _command,
            source: _source,
            market: _market,
            collateralDelta: _collateralDelta,
            sizeDelta: _sizeDelta,
            triggerPrice: _triggerPrice,
            acceptablePrice: _acceptablePrice,
            referrer: _referrer
        });

        ++taskId;
    }

    function _updateGelatoTask(
        uint256 _taskId,
        int256 _collateralDelta,
        int256 _sizeDelta,
        uint256 _triggerPrice,
        uint256 _acceptablePrice
    ) internal {
        Task storage task = _tasks[_taskId];
        if (task.gelatoTaskId == 0) revert NoTaskFound();
        if (_sizeDelta != 0) task.sizeDelta = _sizeDelta;
        if (_collateralDelta != 0) task.collateralDelta = _collateralDelta;
        if (_triggerPrice != 0) task.triggerPrice = _triggerPrice;
        if (_acceptablePrice != 0) task.acceptablePrice = _acceptablePrice;

        EVENTS.emitUpdateGelatoTask({
            taskId: _taskId,
            gelatoTaskId: task.gelatoTaskId,
            collateralDelta: task.collateralDelta,
            sizeDelta: task.sizeDelta,
            triggerPrice: task.triggerPrice,
            acceptablePrice: task.acceptablePrice
        });
    }

    function _cancelGelatoTask(uint256 _taskId) internal {
        Task memory task = getTask(_taskId);
        ITaskCreator(TASK_CREATOR).cancelTask(task.gelatoTaskId);
        EVENTS.emitCancelGelatoTask({
            taskId: _taskId,
            gelatoTaskId: task.gelatoTaskId,
            reason: "MANUAL"
        });
    }

    function _perpInit() internal virtual {}

    function _perpCreateAccount() internal virtual {}

    function _perpModifyCollateral(bytes calldata _inputs) internal virtual {}

    function _perpPlaceOrder(bytes calldata _inputs) internal virtual {}

    function _perpCloseOrder(bytes calldata _inputs) internal virtual {}

    function _perpClosePosition(
        uint128 _accountId,
        uint256 _market,
        uint256 _acceptablePrice
    ) internal virtual {}

    function _perpWithdrawAllMargin(bytes calldata _inputs) internal virtual {}

    function _perpExecuteTask(
        uint256 _taskId,
        Task memory _task
    ) internal virtual {}

    // function _orderKey(
    //     address _market,
    //     uint256 _intentionTime
    // ) internal pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(_market, _intentionTime));
    // }

    function _abs(int256 x) internal pure returns (uint256 z) {
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    function _isSameSign(int256 x, int256 y) internal pure returns (bool) {
        assert(x != 0 && y != 0);
        return (x ^ y) >= 0;
    }
}
