// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGainsTrading {
    enum TradeType {
        TRADE,
        LIMIT,
        STOP
    }

    enum CounterType {
        TRADE,
        PENDING_ORDER
    }

    struct Trade {
        // slot 1
        address user; // 160 bits
        uint32 index; // max: 4,294,967,295
        uint16 pairIndex; // max: 65,535
        uint24 leverage; // 1e3; max: 16,777.215
        bool long; // 8 bits
        bool isOpen; // 8 bits
        uint8 collateralIndex; // max: 255
        // slot 2
        TradeType tradeType; // 8 bits
        uint120 collateralAmount; // 1e18; max: 3.402e+38
        uint64 openPrice; // 1e10; max: 1.8e19
        uint64 tp; // 1e10; max: 1.8e19
        // slot 3 (192 bits left)
        uint64 sl; // 1e10; max: 1.8e19
        uint192 __placeholder;
    }

    struct Counter {
        uint32 currentIndex;
        uint32 openCount;
        uint192 __placeholder;
    }

    function getTrade(
        address _trader,
        uint32 _index
    ) external view returns (Trade memory);

    function openTrade(
        Trade calldata trade,
        uint16 _maxSlippageP,
        address _referrer
    ) external;

    function closeTradeMarket(uint32 _index, uint64 _expectedPrice) external;

    function cancelOpenOrder(uint32 _index) external;

    function getCounters(
        address _trader,
        CounterType _type
    ) external view returns (Counter memory);

    function updateTp(uint32 _index, uint64 _newTp) external;

    function updateSl(uint32 _index, uint64 _newSl) external;

    function updateLeverage(uint32 _index, uint24 _newLeverage) external;

    function increasePositionSize(
        uint32 _index,
        uint120 _collateralDelta,
        uint24 _leverageDelta,
        uint64 _expectedPrice,
        uint16 _maxSlippageP
    ) external;

    function decreasePositionSize(
        uint32 _index,
        uint120 _collateralDelta,
        uint24 _leverageDelta
    ) external;
}
