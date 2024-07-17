// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ICopyWalletGNSv8 {
    error ExecutionFeeNotEnough();

    enum OrderType {
        OPEN,
        INCREASE,
        DECREASE
    }

    struct TraderPosition {
        address trader;
        uint32 index;
        uint64 __placeholder;
    }
    struct ConstructorParams {
        address factory;
        address events;
        address configs;
        address usdAsset;
        address automate;
        address taskCreator;
        address gainsTrading;
        address pyth;
    }

    error TradeMismatch();

    error InvalidLeverage();

    error InvalidCollateralDelta();

    error TradeOpening();

    error AlreadyCharged();
}
