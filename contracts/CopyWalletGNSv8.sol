// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ICopyWallet} from "contracts/interfaces/ICopyWallet.sol";
import {IConfigs} from "contracts/interfaces/IConfigs.sol";
import {ICopyWalletGNSv8} from "contracts/interfaces/ICopyWalletGNSv8.sol";
import {CopyWallet} from "contracts/core/CopyWallet.sol";
import {IRouter} from "contracts/interfaces/GMXv1/IRouter.sol";
import {IPositionRouter} from "contracts/interfaces/GMXv1/IPositionRouter.sol";
import {IVault} from "contracts/interfaces/GMXv1/IVault.sol";
import {IPyth} from "contracts/interfaces/pyth/IPyth.sol";
import {PythStructs} from "contracts/interfaces/pyth/PythStructs.sol";
import {IGainsTrading} from "contracts/interfaces/GNSv8/IGainsTrading.sol";

contract CopyWalletGNSv8 is CopyWallet, ICopyWalletGNSv8 {
    /* ========== CONSTANTS ========== */
    bytes32 internal constant ETH_PRICE_FEED =
        0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
    /* ========== IMMUTABLES ========== */
    IGainsTrading internal immutable GAINS_TRADING;
    IPyth internal immutable PYTH;

    mapping(bytes32 => uint32) _keyIndexes;
    mapping(uint32 => TraderPosition) _traderPositions;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        ConstructorParams memory _params
    )
        CopyWallet(
            ICopyWallet.CopyWalletConstructorParams({
                factory: _params.factory,
                events: _params.events,
                configs: _params.configs,
                usdAsset: _params.usdAsset,
                automate: _params.automate,
                taskCreator: _params.taskCreator
            })
        )
    {
        GAINS_TRADING = IGainsTrading(_params.gainsTrading);
        PYTH = IPyth(_params.pyth);
    }

    /* ========== VIEWS ========== */

    function ethToUsd(uint256 _amount) public view override returns (uint256) {
        PythStructs.Price memory price = PYTH.getPriceUnsafe(ETH_PRICE_FEED);
        return (_convertToUint(price, 6) * _amount) / 10 ** 18;
    }

    function getTraderPosition(
        uint32 _index
    ) external view returns (TraderPosition memory traderPosition) {
        traderPosition = _traderPositions[_index];
    }

    function getKeyIndex(
        address _source,
        uint32 _sourceIndex
    ) external view returns (uint32 index) {
        bytes32 key = keccak256(
            abi.encodePacked(_source, uint256(_sourceIndex))
        );
        index = _keyIndexes[key];
    }

    /* ========== PERPS ========== */

    function closePosition(uint32 _index) external nonReentrant {
        if (!isOwner(msg.sender)) revert Unauthorized();
        TraderPosition memory traderPosition = _traderPositions[_index];
        bytes32 key = keccak256(
            abi.encodePacked(
                traderPosition.trader,
                uint256(traderPosition.index)
            )
        );
        _closeOrder(traderPosition.trader, key, _index);
    }

    function _perpInit() internal override {}

    function _perpWithdrawAllMargin(bytes calldata _inputs) internal override {}

    function _perpModifyCollateral(bytes calldata _inputs) internal override {
        uint32 index;
        uint120 collateral;
        bool isIncrease;
        assembly {
            index := calldataload(_inputs.offset)
            collateral := calldataload(add(_inputs.offset, 0x20))
            isIncrease := calldataload(add(_inputs.offset, 0x40))
        }

        IGainsTrading.Trade memory trade = GAINS_TRADING.getTrade(
            address(this),
            index
        );

        if (!trade.isOpen) {
            revert NoOpenPosition();
        }

        uint120 newCollateral = trade.collateralAmount + collateral;

        if (isIncrease) {
            USD_ASSET.approve(address(GAINS_TRADING), (collateral * 105) / 100); // 5% safety
        } else {
            if (uint120(collateral) >= trade.collateralAmount) {
                revert InvalidCollateralDelta();
            }
            newCollateral = trade.collateralAmount - collateral;
        }
        uint24 newLeverage = uint24(
            (trade.collateralAmount * uint120(trade.leverage)) / newCollateral
        );

        if (newLeverage < 2000 || newLeverage > 150000) {
            revert InvalidLeverage();
        }

        GAINS_TRADING.updateLeverage(index, newLeverage);
    }

    function _perpUpdateSltp(bytes calldata _inputs) internal override {
        uint32 index;
        uint64 tp;
        uint64 sl;
        assembly {
            index := calldataload(_inputs.offset)
            tp := calldataload(add(_inputs.offset, 0x20))
            sl := calldataload(add(_inputs.offset, 0x40))
        }
        if (sl > 0) {
            GAINS_TRADING.updateSl(index, sl);
        }
        if (tp > 0) {
            GAINS_TRADING.updateTp(index, tp);
        }
    }

    function _perpCancelOrder(bytes calldata _inputs) internal override {
        uint32 index;
        assembly {
            index := calldataload(_inputs.offset)
        }
        GAINS_TRADING.cancelOpenOrder(index);
    }

    function _perpPlaceOrder(bytes calldata _inputs) internal override {
        address source;
        uint32 sourceIndex;
        uint16 pairIndex;
        bool isLong;
        uint120 collateral;
        uint24 leverage;
        uint64 price;
        uint64 tp;
        uint64 sl;
        OrderType orderType;
        assembly {
            source := calldataload(_inputs.offset)
            sourceIndex := calldataload(add(_inputs.offset, 0x20))
            pairIndex := calldataload(add(_inputs.offset, 0x40))
            isLong := calldataload(add(_inputs.offset, 0x60))
            collateral := calldataload(add(_inputs.offset, 0x80))
            leverage := calldataload(add(_inputs.offset, 0xa0))
            price := calldataload(add(_inputs.offset, 0xc0))
            tp := calldataload(add(_inputs.offset, 0xe0))
            sl := calldataload(add(_inputs.offset, 0x100))
            orderType := calldataload(add(_inputs.offset, 0x120))
        }
        if (orderType == OrderType.OPEN) {
            _openTrade({
                _source: source,
                _sourceIndex: sourceIndex,
                _pairIndex: pairIndex,
                _isLong: isLong,
                _collateral: collateral,
                _leverage: leverage,
                _price: price,
                _tp: tp,
                _sl: sl
            });
        } else {
            _updateTrade({
                _source: source,
                _sourceIndex: sourceIndex,
                _pairIndex: pairIndex,
                _isLong: isLong,
                _isIncrease: orderType == OrderType.INCREASE,
                _collateral: collateral,
                _leverage: leverage,
                _price: price,
                _tp: tp,
                _sl: sl
            });
        }
    }

    function _perpCloseOrder(bytes calldata _inputs) internal override {
        address source;
        uint32 sourceIndex;
        assembly {
            source := calldataload(_inputs.offset)
            sourceIndex := calldataload(add(_inputs.offset, 0x20))
        }

        bytes32 key = keccak256(abi.encodePacked(source, uint256(sourceIndex)));
        uint32 index = _keyIndexes[key];
        TraderPosition memory traderPosition = _traderPositions[index];

        if (
            traderPosition.trader != source ||
            traderPosition.index != sourceIndex
        ) {
            revert SourceMismatch();
        }

        _closeOrder(source, key, index);
    }

    function _openTrade(
        address _source,
        uint32 _sourceIndex,
        uint16 _pairIndex,
        bool _isLong,
        uint120 _collateral,
        uint24 _leverage,
        uint64 _price,
        uint64 _tp,
        uint64 _sl
    ) internal {
        bytes32 key = keccak256(
            abi.encodePacked(_source, uint256(_sourceIndex))
        );
        if (_keyIndexes[key] > 0) {
            IGainsTrading.Trade memory lastTrade = GAINS_TRADING.getTrade(
                address(this),
                _keyIndexes[key]
            );
            if (lastTrade.isOpen) {
                revert PositionExist();
            }
        }
        IGainsTrading.Counter memory counter = GAINS_TRADING.getCounters(
            address(this),
            IGainsTrading.CounterType.TRADE
        );
        IGainsTrading.Trade memory trade;
        trade.user = address(this);
        trade.isOpen = true;
        trade.long = _isLong;
        trade.collateralIndex = 3;
        trade.pairIndex = _pairIndex;
        trade.collateralAmount = _collateral;
        trade.leverage = _leverage;
        trade.openPrice = _price;
        trade.tp = _tp;
        trade.sl = _sl;
        trade.index = counter.currentIndex;

        TraderPosition memory traderPosition = TraderPosition({
            trader: _source,
            index: _sourceIndex,
            __placeholder: 0
        });

        _keyIndexes[key] = trade.index;
        _traderPositions[trade.index] = traderPosition;

        USD_ASSET.approve(address(GAINS_TRADING), _collateral);

        GAINS_TRADING.openTrade(trade, 300, CONFIGS.feeReceiver());

        _postOrder({
            _id: uint256(key),
            _source: _source,
            _lastSizeUsd: 0,
            _sizeDeltaUsd: (_collateral * _leverage) / 1000,
            _isIncrease: true
        });
    }

    function _updateTrade(
        address _source,
        uint32 _sourceIndex,
        uint16 _pairIndex,
        bool _isLong,
        bool _isIncrease,
        uint120 _collateral,
        uint24 _leverage,
        uint64 _price,
        uint64 _tp,
        uint64 _sl
    ) internal {
        bytes32 key = keccak256(
            abi.encodePacked(_source, uint256(_sourceIndex))
        );
        IGainsTrading.Trade memory trade = GAINS_TRADING.getTrade(
            address(this),
            _keyIndexes[key]
        );
        if (!trade.isOpen) {
            revert NoOpenPosition();
        }
        if (trade.pairIndex != _pairIndex || trade.long != _isLong) {
            revert TradeMismatch();
        }

        if (_isIncrease) {
            USD_ASSET.approve(address(GAINS_TRADING), _collateral);
            GAINS_TRADING.increasePositionSize({
                _index: trade.index,
                _collateralDelta: _collateral,
                _leverageDelta: _leverage,
                _expectedPrice: _price,
                _maxSlippageP: 300
            });
        } else {
            GAINS_TRADING.decreasePositionSize({
                _index: trade.index,
                _collateralDelta: _collateral,
                _leverageDelta: 0
            });
        }

        if (_tp > 0) {
            GAINS_TRADING.updateTp(trade.index, _tp);
        }

        if (_sl > 0) {
            GAINS_TRADING.updateSl(trade.index, _sl);
        }

        _postOrder({
            _id: uint256(key),
            _source: _source,
            _lastSizeUsd: (trade.collateralAmount * trade.leverage) / 1000,
            _sizeDeltaUsd: (_collateral * _leverage) / 1000,
            _isIncrease: _isIncrease
        });
    }

    function _closeOrder(
        address _source,
        bytes32 _key,
        uint32 _index
    ) internal {
        IGainsTrading.Trade memory trade = GAINS_TRADING.getTrade(
            address(this),
            _index
        );

        GAINS_TRADING.closeTradeMarket(_index);

        uint256 size = (trade.collateralAmount * trade.leverage) / 1000;

        _postOrder({
            _id: uint256(_key),
            _source: _source,
            _lastSizeUsd: size,
            _sizeDeltaUsd: size,
            _isIncrease: false
        });
    }

    /* ========== TASKS ========== */

    // TODO task
    // function _perpValidTask(
    //     Task memory _task
    // ) internal view override returns (bool) {
    //     uint256 price = _indexPrice(address(uint160(_task.market)));
    //     if (_task.command == TaskCommand.STOP_ORDER) {
    //         if (_task.sizeDelta > 0) {
    //             // Long: increase position size (buy) once *above* trigger price
    //             // ex: unwind short position once price is above target price (prevent further loss)
    //             return price >= _task.triggerPrice;
    //         } else {
    //             // Short: decrease position size (sell) once *below* trigger price
    //             // ex: unwind long position once price is below trigger price (prevent further loss)
    //             return price <= _task.triggerPrice;
    //         }
    //     } else if (_task.command == TaskCommand.LIMIT_ORDER) {
    //         if (_task.sizeDelta > 0) {
    //             // Long: increase position size (buy) once *below* trigger price
    //             // ex: open long position once price is below trigger price
    //             return price <= _task.triggerPrice;
    //         } else {
    //             // Short: decrease position size (sell) once *above* trigger price
    //             // ex: open short position once price is above trigger price
    //             return price >= _task.triggerPrice;
    //         }
    //     }
    //     return false;
    // }
    // function _perpExecuteTask(
    //     uint256 _taskId,
    //     Task memory _task
    // ) internal override {
    //     bool isLong = _task.command == TaskCommand.LIMIT_ORDER && _task.sizeDelta > 0 || task.command == TaskCommand.STOP_ORDER && _task.sizeDelta < 0;
    //     // if margin was locked, free it
    //     if (_task.collateralDelta > 0) {
    //         lockedFund -= _abs(_task.collateralDelta);
    //     }
    //     if (_task.command == TaskCommand.STOP_ORDER) {
    //         (uint256 sizeUsdD30,,uint256 averagePriceD30) = getPosition(address(this), address(USD_ASSET), market, isLong);
    //         if (
    //             sizeUsdD30 == 0 ||
    //             _isSameSign(sizeUsdD30 * isLong ? 1 : -1 , _task.sizeDelta)
    //         ) {
    //             EVENTS.emitCancelGelatoTask({
    //                 taskId: _taskId,
    //                 gelatoTaskId: _task.gelatoTaskId,
    //                 reason: "INVALID_SIZE"
    //             });
    //             return;
    //         }
    //         if (_abs(_task.sizeDelta) > sizeUsdD30 / 10 ** 12) {
    //             // bound conditional order size delta to current position size
    //             _task.sizeDelta = -int256(sizeUsdD30 / 10 ** 12);
    //         }
    //     }

    //     if (_task.collateralDelta != 0) {
    //         if (_task.collateralDelta > 0) {
    //             _sufficientFund(_task.collateralDelta, true);
    //         }
    //     }
    //     _placeOrder({
    //         _source: _task.source,
    //         _market: address(uint160(_task.market)),
    //         _isLong: isLong,
    //         _isIncrease: _task.command == TaskCommand.LIMIT_ORDER,
    //         _collateralDelta: _task.collateralDelta > 0 ? _abs(_task.collateralDelta) : 0,
    //         _sizeUsdDelta: _abs(_task.sizeDelta),
    //         _acceptablePrice: _task.acceptablePrice
    //     });
    // }

    /* ========== UTILITIES ========== */

    function _convertToUint(
        PythStructs.Price memory price,
        uint8 targetDecimals
    ) private pure returns (uint256) {
        if (price.price < 0 || price.expo > 0 || price.expo < -255) {
            revert();
        }

        uint8 priceDecimals = uint8(uint32(-1 * price.expo));

        if (targetDecimals >= priceDecimals) {
            return
                uint(uint64(price.price)) *
                10 ** uint32(targetDecimals - priceDecimals);
        } else {
            return
                uint(uint64(price.price)) /
                10 ** uint32(priceDecimals - targetDecimals);
        }
    }
}
