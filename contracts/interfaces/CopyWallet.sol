// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IGainsTrading} from "../interfaces/IGainsTrading.sol";
import {ICopyWallet} from "../interfaces/ICopyWallet.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IConfigs} from "../interfaces/IConfigs.sol";
import {IEvents} from "../interfaces/IEvents.sol";
import {IERC20} from "../interfaces/token/IERC20.sol";
import {Owned} from "../utils/Owned.sol";

contract CopyWallet is Owned, ReentrancyGuard, ICopyWallet {
    /* ========== CONSTANTS ========== */

    bytes32 public constant VERSION = "0.1.0";

    /* ========== IMMUTABLES ========== */

    IFactory internal immutable FACTORY;
    IEvents internal immutable EVENTS;
    IConfigs internal immutable CONFIGS;
    IERC20 internal immutable USD_ASSET; // USD token
    IGainsTrading internal immutable GAINS_TRADING;

    /* ========== STATES ========== */

    uint256 public lockedFund;

    /* ========== CONSTRUCTOR ========== */

    constructor(CopyWalletConstructorParams memory _params) Owned(address(0)) {
        FACTORY = IFactory(_params.factory);
        EVENTS = IEvents(_params.events);
        CONFIGS = IConfigs(_params.configs);
        USD_ASSET = IERC20(_params.usdAsset);
        GAINS_TRADING = IGainsTrading(_params.gainsTrading);
    }

    /* ========== VIEWS ========== */

    function availableFund() public view override returns (uint256) {
        return USD_ASSET.balanceOf(address(this)) - lockedFund;
    }

    function availableFundD18() public view override returns (uint256) {
        return _usdToD18(availableFund());
    }

    function lockedFundD18() public view override returns (uint256) {
        return _usdToD18(lockedFund);
    }

    /* ========== INIT & OWNERSHIP ========== */

    function init(address _owner) external {
        require(msg.sender == address(FACTORY), "Unauthorized");
        _setInitialOwnership(_owner);
    }

    function _setInitialOwnership(address _owner) private {
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function transferOwnership(address _newOwner) public override {
        super.transferOwnership(_newOwner);
        FACTORY.updateCopyWalletOwnership({
            _newOwner: _newOwner,
            _oldOwner: msg.sender
        });
    }

    /* ========== FUNDS ========== */

    receive() external payable {}

    function withdrawEth(uint256 _amount) external onlyOwner {
        _withdrawEth(_amount);
    }

    function modifyFund(int256 _amount) external onlyOwner {
        _modifyFund(_amount);
    }

    function _withdrawEth(uint256 _amount) internal {
        if (_amount > 0) {
            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "Eth withdrawal failed");
            EVENTS.emitEthWithdraw({user: msg.sender, amount: _amount});
        }
    }

    function _modifyFund(int256 _amount) internal {
        /// @dev if amount is positive, deposit
        if (_amount > 0) {
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            USD_ASSET.transferFrom(msg.sender, address(this), _abs(_amount));
            EVENTS.emitDeposit({user: msg.sender, amount: _abs(_amount)});
        } else if (_amount < 0) {
            /// @dev if amount is negative, withdraw
            _sufficientFund(_amount, true);
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            USD_ASSET.transfer(msg.sender, _abs(_amount));
            EVENTS.emitWithdraw({user: msg.sender, amount: _abs(_amount)});
        }
    }

    function _lockFund(int256 _amount, bool origin) internal {
        _sufficientFund(_amount, origin);
        lockedFund += origin ? _abs(_amount) : _d18ToUsd(_abs(_amount));
    }

    /* ========== FEES ========== */

    function _chargeProtocolFee(uint256 _feeUsd) internal {
        address feeReceiver = CONFIGS.feeReceiver();
        USD_ASSET.transfer(feeReceiver, _feeUsd);
        EVENTS.emitChargeProtocolFee({receiver: feeReceiver, feeUsd: _feeUsd});
    }

    /* ========== PERPS ========== */

    // function _preOrder(
    //     uint256 _id,
    //     uint256 _lastSize,
    //     uint256 _sizeDelta,
    //     uint256 _price,
    //     bool _isIncrease
    // ) internal {}

    function openTrade(
        IGainsTrading.Trade memory trade,
        uint16 _maxSlippageP
    ) external onlyOwner {
        require(trade.collateralIndex == 3, "Only support USDC");
        USD_ASSET.approve(address(GAINS_TRADING), trade.collateralAmount);
        GAINS_TRADING.openTrade(trade, _maxSlippageP, CONFIGS.feeReceiver());
    }

    function closeTradeMarket(uint32 _index) external onlyOwner {
        _closeTradeMarket(_index);
    }

    function _openTrade(
        IGainsTrading.Trade memory trade,
        uint16 _maxSlippageP
    ) internal {
        GAINS_TRADING.openTrade(trade, _maxSlippageP, CONFIGS.feeReceiver());
        uint256 fees = _protocolFee(trade.collateralAmount * trade.leverage);
        _lockFund(int256(fees), true);
    }

    function _closeTradeMarket(uint32 _index) internal {
        GAINS_TRADING.closeTradeMarket(_index);
        _chargeProtocolFee(lockedFund);
        lockedFund = 0;
    }

    /* ========== INTERNAL GETTERS ========== */

    function _protocolFee(uint256 _size) internal view returns (uint256) {
        return _size / IConfigs(CONFIGS).protocolFee();
    }

    function _sufficientFund(int256 _amountOut, bool origin) internal view {
        /// @dev origin true => amount as fund asset decimals
        uint256 _fundOut = origin
            ? _abs(_amountOut)
            : _d18ToUsd(_abs(_amountOut));
        require(_fundOut <= availableFund(), "Insufficient available fund");
    }

    /* ========== UTILITIES ========== */

    function _d18ToUsd(uint256 _amount) internal view returns (uint256) {
        /// @dev convert to fund asset decimals
        return (_amount * 10 ** USD_ASSET.decimals()) / 10 ** 18;
    }

    function _usdToD18(uint256 _amount) internal view returns (uint256) {
        /// @dev convert to fund asset decimals
        return (_amount * 10 ** 18) / 10 ** USD_ASSET.decimals();
    }

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
