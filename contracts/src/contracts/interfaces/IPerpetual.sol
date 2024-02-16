// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import {Epoch, EpochLibrary} from "../libraries/EpochLibrary.sol";

interface IPerpetual {
    struct IncreasePositionParams {
        address collateralToken;
        address indexToken;
        int24 tickLower;
        bool isLong;
        uint256 collateralAmount;
        uint256 indexAmount;
    }

    struct DecreasePositionParams {
        address collateralToken;
        address indexToken;
        bool isLong;
    }

    struct Position {
        uint256 size;
        uint256 collateralAmount;
        uint256 debt;
        uint160 liquidity;
        int24 tick;
        Epoch epoch;
        int256 realisedPnl;
    }

    struct SwapCallbackData {
        address payer;
        address token;
    }

    error InvalidPositionPrice(uint160 currentPrice, uint160 positionPrice);
    error VaultNotExists();
    error PositionNotFound();
    error PositionNotFulfilled();
    error InvalidCollateralDelta(uint256 collateral, uint256 collateralDelta);
    error InvalidDebtDelta(uint256 debt, uint256 debtDelta);
    error InvalidLiquidityDelta(uint160 liquidity, uint160 liquidityDelta);
    error InsufficientBalance();

    event IncreasePosition(
        address indexed account,
        address indexed collateralToken,
        address indexed indexToken,
        bool isLong,
        uint256 sizeDelta,
        uint256 collateralDelta,
        uint256 debtDelta,
        uint160 liquidityDelta,
        int24 tick
    );

    event DecreasePosition(
        address indexed account,
        address indexed collateralToken,
        address indexed indexToken,
        bool isLong,
        uint256 sizeDelta,
        uint256 collateralDelta,
        uint256 debtDelta,
        uint160 liquidityDelta,
        int24 tick
    );

    function increasePosition(
        IncreasePositionParams calldata _params
    ) external returns (uint128 liquidityDelta, uint256 sizeDelta);

    function decreasePosition(
        DecreasePositionParams calldata _params
    ) external returns (uint128 liquidityDelta, uint256 sizeDelta);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (Position memory);
}
