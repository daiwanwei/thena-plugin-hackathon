// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraFactory.sol";
import "@cryptoalgebra/integral-periphery/contracts/libraries/PoolAddress.sol";
import "./interfaces/ILimitOrderPlugin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LiquidityMath} from "@cryptoalgebra/integral-core/contracts/libraries/LiquidityMath.sol";
import {TickMath} from "@cryptoalgebra/integral-core/contracts/libraries/TickMath.sol";
import {PositionKey2} from "./libraries/PositionKey2.sol";
import {LiquidityAmounts} from "@cryptoalgebra/integral-periphery/contracts/libraries/LiquidityAmounts.sol";
import {Epoch, EpochLibrary} from "./libraries/EpochLibrary.sol";
import "./LimitOrderPlugin.sol";
import {console2} from "forge-std/Test.sol";
import "./interfaces/IPerpetual.sol";
import "@cryptoalgebra/integral-periphery/contracts/interfaces/ISwapRouter.sol";
import "./interfaces/IVaultFactory.sol";
import "./interfaces/IVault.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract Perpetual is IPerpetual {
    using EpochLibrary for Epoch;
    using Math for uint256;
    IAlgebraFactory public algebraFactory;
    ILimitOrderPlugin public limitOrderPlugin;
    ISwapRouter public swapRouter;
    IVaultFactory public vaultFactory;
    mapping(bytes32 => Position) public positions;

    constructor(
        address _algebraFactory,
        address _limitOrderPlugin,
        address _swapRouter,
        address _vaultFactory
    ) {
        algebraFactory = IAlgebraFactory(_algebraFactory);
        limitOrderPlugin = LimitOrderPlugin(_limitOrderPlugin);
        swapRouter = ISwapRouter(_swapRouter);
        vaultFactory = IVaultFactory(_vaultFactory);
    }

    function increasePosition(
        IncreasePositionParams calldata _params
    ) public returns (uint128 liquidityDelta, uint256 sizeDelta) {
        if (_params.isLong != true) {
            revert NotImplemented();
        }

        if (
            checkPosition(
                msg.sender,
                _params.collateralToken,
                _params.indexToken,
                _params.isLong
            )
        ) {
            revert PositionAlreadyExisted();
        }

        int24 _tickLower = TickMath.getTickAtSqrtRatio(_params.takeProfitPrice);
        bool _isToken0Long = isToken0Long(
            _params.collateralToken,
            _params.indexToken,
            _params.isLong
        );
        (
            uint160 _entryPrice,
            uint160 _takeProfitPrice
        ) = getEntryAndTakeProfitPrice(
                _params.collateralToken,
                _params.indexToken,
                _tickLower
            );
        validatePositionPrice(_entryPrice, _takeProfitPrice, _isToken0Long);
        _deposit(_params.collateralToken, msg.sender, _params.collateralAmount);
        _borrow(
            msg.sender,
            _params.collateralToken,
            _params.indexToken,
            _params.collateralAmount,
            _params.indexAmount
        );
        sizeDelta = _swap(
            _params.indexToken,
            _params.collateralToken,
            _params.indexAmount,
            0,
            address(swapRouter)
        );

        liquidityDelta = _placeOrder(
            _params.collateralToken > _params.indexToken
                ? _params.indexToken
                : _params.collateralToken,
            _params.collateralToken > _params.indexToken
                ? _params.collateralToken
                : _params.indexToken,
            _tickLower,
            _isToken0Long,
            sizeDelta
        );

        Epoch epoch = getEpoch(
            _params.collateralToken,
            _params.indexToken,
            _tickLower,
            _isToken0Long
        );

        _updatePosition(
            msg.sender,
            _params.collateralToken,
            _params.indexToken,
            _params.isLong,
            sizeDelta,
            _params.collateralAmount,
            _params.indexAmount,
            liquidityDelta,
            _entryPrice,
            _takeProfitPrice,
            epoch,
            true
        );
    }

    function decreasePosition(
        DecreasePositionParams calldata _params
    ) public returns (uint128 liquidityDelta, uint256 sizeDelta) {
        if (_params.isLong != true) {
            revert NotImplemented();
        }

        if (
            !checkPosition(
                msg.sender,
                _params.collateralToken,
                _params.indexToken,
                _params.isLong
            )
        ) {
            revert PositionNotExisted();
        }
        address _collateralToken = _params.collateralToken;
        address _indexToken = _params.indexToken;
        bool _isLong = _params.isLong;
        bool _isToken0Long = isToken0Long(
            _collateralToken,
            _indexToken,
            _isLong
        );

        Position memory position = _getPosition(
            msg.sender,
            _collateralToken,
            _indexToken,
            _isLong
        );
        liquidityDelta = uint128(position.liquidity);
        sizeDelta = position.size;

        if (position.liquidity <= 0) {
            revert PositionNotFound();
        }

        (uint256 amount0, uint256 amount1) = _claimOrder(
            position.epoch,
            uint128(position.liquidity)
        );

        uint256 indexAmount = _isToken0Long ? amount1 : amount0;
        _repay(
            msg.sender,
            _collateralToken,
            _indexToken,
            position.collateralAmount,
            position.debt
        );
        _refund(_indexToken, msg.sender, indexAmount - position.debt);

        _updatePosition(
            msg.sender,
            _collateralToken,
            _indexToken,
            _isLong,
            position.size,
            position.collateralAmount,
            position.debt,
            position.liquidity,
            position.entryPrice,
            position.takeProfitPrice,
            position.epoch,
            false
        );
        _removePosition(msg.sender, _collateralToken, _indexToken, _isLong);
    }

    function killPosition(
        KillPositionParams calldata _params
    ) public returns (uint256 collateralDelta, uint256 indexDelta) {
        address _collateralToken = _params.collateralToken;
        address _indexToken = _params.indexToken;
        bool _isLong = _params.isLong;
        bool _isToken0Long = isToken0Long(
            _collateralToken,
            _indexToken,
            _isLong
        );

        Position memory position = _getPosition(
            msg.sender,
            _collateralToken,
            _indexToken,
            _isLong
        );

        if (position.liquidity <= 0) {
            revert PositionNotFound();
        }
        int24 _tickLower = TickMath.getTickAtSqrtRatio(
            position.takeProfitPrice
        );
        (uint256 amount0, uint256 amount1) = _killOrder(
            _collateralToken > _indexToken ? _indexToken : _collateralToken,
            _collateralToken > _indexToken ? _collateralToken : _indexToken,
            _tickLower,
            _isToken0Long,
            uint160(position.liquidity)
        );

        uint256 indexAmount = _isToken0Long ? amount1 : amount0;
        uint256 collateralAmount = _isToken0Long ? amount0 : amount1;

        uint256 indexForRepay = _swap(
            _collateralToken,
            _indexToken,
            collateralAmount,
            0,
            address(swapRouter)
        ) + indexAmount;

        if (indexForRepay > position.debt) {
            collateralDelta = position.collateralAmount;
            indexDelta = indexForRepay - position.debt;
            _repay(
                msg.sender,
                _collateralToken,
                _indexToken,
                position.collateralAmount,
                position.debt
            );
            _refund(_indexToken, msg.sender, indexDelta);
        } else {
            indexDelta = 0;
            collateralDelta = _kill(
                msg.sender,
                _collateralToken,
                _indexToken,
                indexForRepay
            );
        }
        //        _updatePosition(
        //            msg.sender,
        //            _collateralToken,
        //            _indexToken,
        //            _isLong,
        //            position.size,
        //            position.collateralAmount,
        //            position.debt,
        //            position.liquidity,
        //            position.entryPrice,
        //            position.takeProfitPrice,
        //            position.epoch,
        //            false
        //        );
        _removePosition(msg.sender, _collateralToken, _indexToken, _isLong);
    }

    function _placeOrder(
        address _token0,
        address _token1,
        int24 _tickLower,
        bool _isToken0Long,
        uint256 _size
    ) private returns (uint128 liquidity) {
        IAlgebraPool pool = getPool(_token0, _token1);
        int24 _tickSpacing = pool.tickSpacing();
        liquidity = getLiquidityForAmounts(
            _token0,
            _token1,
            _tickLower,
            _tickLower + _tickSpacing,
            _isToken0Long ? _size : 0,
            _isToken0Long ? 0 : _size
        );
        console2.log("liquidity: %s", liquidity);
        bool _zeroForOne = _isToken0Long;

        IERC20 token = _isToken0Long ? IERC20(_token0) : IERC20(_token1);
        token.approve(address(limitOrderPlugin), _size);
        limitOrderPlugin.place(
            PoolAddress.PoolKey({token0: _token0, token1: _token1}),
            _tickLower,
            _zeroForOne,
            liquidity
        );
    }

    function _claimOrder(
        Epoch _epoch,
        uint128 _liquidity
    ) private returns (uint256 amount0, uint256 amount1) {
        if (!limitOrderPlugin.isFilled(_epoch)) {
            revert PositionNotFulfilled();
        }
        (amount0, amount1) = limitOrderPlugin.withdraw(
            _epoch,
            address(this),
            _liquidity
        );
    }

    function _killOrder(
        address _token0,
        address _token1,
        int24 _tickLower,
        bool _isToken0Long,
        uint160 _liquidityDelta
    ) private returns (uint256 amount0, uint256 amount1) {
        IAlgebraPool pool = getPool(_token0, _token1);
        int24 _tickSpacing = pool.tickSpacing();
        bool _zeroForOne = _isToken0Long;
        ILimitOrderPlugin.KillParams memory params = ILimitOrderPlugin
            .KillParams({
                poolKey: PoolAddress.PoolKey({
                    token0: _token0,
                    token1: _token1
                }),
                tickLower: _tickLower,
                tickUpper: _tickLower + _tickSpacing,
                zeroForOne: _zeroForOne,
                to: address(this),
                liquidityDelta: uint128(_liquidityDelta)
            });
        (amount0, amount1) = limitOrderPlugin.kill(params);
    }

    function _deposit(address _token, address _payer, uint256 _amount) private {
        IERC20 token = IERC20(_token);
        if (token.balanceOf(_payer) < _amount) {
            revert InsufficientBalance();
        }
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function _refund(
        address _token,
        address _recipient,
        uint256 _amount
    ) private {
        IERC20 token = IERC20(_token);
        if (token.balanceOf(address(this)) < _amount) {
            revert InsufficientBalance();
        }
        token.transfer(_recipient, _amount);
    }

    function _updatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _collateralDelta,
        uint256 _debtDelta,
        uint160 _liquidityDelta,
        uint160 _entryPrice,
        uint160 _takeProfitPrice,
        Epoch _epoch,
        bool _isIncrease
    ) private {
        Position storage position = _getPosition(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        );
        position.entryPrice = _entryPrice;
        position.takeProfitPrice = _takeProfitPrice;
        position.epoch = _epoch;
        if (_isIncrease) {
            position.size += _sizeDelta;
            position.collateralAmount += _collateralDelta;
            position.debt += _debtDelta;
            position.liquidity += _liquidityDelta;
            emit IncreasePosition(
                msg.sender,
                _collateralToken,
                _indexToken,
                _isLong,
                _sizeDelta,
                _collateralDelta,
                _debtDelta,
                _liquidityDelta,
                _takeProfitPrice
            );
        } else {
            position.size -= _sizeDelta;
            position.collateralAmount -= _collateralDelta;
            position.debt -= _debtDelta;
            position.liquidity -= _liquidityDelta;
            emit DecreasePosition(
                msg.sender,
                _collateralToken,
                _indexToken,
                _isLong,
                _sizeDelta,
                _collateralDelta,
                _debtDelta,
                _liquidityDelta,
                _takeProfitPrice
            );
        }
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address _swapRouter
    ) private returns (uint256 amountOut) {
        IERC20 indexToken = IERC20(tokenIn);
        indexToken.approve(address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                recipient: address(this),
                deadline: block.timestamp + 1000,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                limitSqrtPrice: 0
            });
        amountOut = ISwapRouter(_swapRouter).exactInputSingle(params);
    }

    function _borrow(
        address _user,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _indexDelta
    ) private {
        IVault vault = IVault(
            vaultFactory.vaults(_indexToken, _collateralToken)
        );
        if (address(vault) == address(0)) {
            revert VaultNotExists();
        }
        IERC20 collateralToken = IERC20(_collateralToken);
        collateralToken.approve(address(vault), _collateralDelta);
        IVault.IncreasePositionParams memory params = IVault
            .IncreasePositionParams({
                user: _user,
                recipient: address(this),
                collateralDelta: _collateralDelta,
                debtDelta: _indexDelta
            });
        vault.increasePosition(params);
    }

    function _repay(
        address _user,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _debtDelta
    ) private {
        IVault vault = IVault(
            vaultFactory.vaults(_indexToken, _collateralToken)
        );
        if (address(vault) == address(0)) {
            revert VaultNotExists();
        }

        (uint256 _collateral, uint256 _debt) = _getPositionFromVault(
            _user,
            _collateralToken,
            _indexToken
        );

        if (_collateral < _collateralDelta) {
            revert InvalidCollateralDelta(_collateral, _collateralDelta);
        }

        if (_debt < _debtDelta) {
            revert InvalidDebtDelta(_debt, _debtDelta);
        }

        IERC20(_indexToken).approve(address(vault), _debtDelta);
        vault.decreasePosition(
            IVault.DecreasePositionParams({
                user: _user,
                payer: address(this),
                collateralDelta: _collateralDelta,
                debtDelta: _debtDelta
            })
        );
    }

    function _kill(
        address _user,
        address _collateralToken,
        address _indexToken,
        uint256 _debtDelta
    ) private returns (uint256 collateralDelta) {
        IVault vault = IVault(
            vaultFactory.vaults(_indexToken, _collateralToken)
        );
        if (address(vault) == address(0)) {
            revert VaultNotExists();
        }

        (uint256 _collateral, uint256 _debt) = _getPositionFromVault(
            _user,
            _collateralToken,
            _indexToken
        );

        if (_debt < _debtDelta) {
            revert InvalidDebtDelta(_debt, _debtDelta);
        }
        IERC20(_indexToken).approve(address(vault), _debtDelta);
        collateralDelta = vault.killPosition(
            IVault.KillPositionParams({
                payer: address(this),
                user: _user,
                debtDelta: _debtDelta
            })
        );
    }

    function _removePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) private {
        bytes32 positionKey = PositionKey2.getPositionKey(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        );
        delete positions[positionKey];
    }

    function getAmountsForLiquidity(
        address _collateralToken,
        address _indexToken,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity
    ) public view returns (uint256 amount0, uint256 amount1) {
        IAlgebraPool pool = getPool(_collateralToken, _indexToken);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool
            .safelyGetStateOfAMM();
        (amount0, amount1, ) = LiquidityMath.getAmountsForLiquidity(
            _tickLower,
            _tickUpper,
            int128(_liquidity),
            tick,
            sqrtPriceX96
        );
    }

    function getLiquidityForAmounts(
        address token0,
        address token1,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _amount0,
        uint256 _amount1
    ) public view returns (uint128 liquidity) {
        IAlgebraPool pool = getPool(token0, token1);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool
            .safelyGetStateOfAMM();
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(_tickLower),
            TickMath.getSqrtRatioAtTick(_tickUpper),
            _amount0,
            _amount1
        );
    }

    function getPool(
        address _token0,
        address _token1
    ) public view returns (IAlgebraPool) {
        return IAlgebraPool(algebraFactory.poolByPair(_token0, _token1));
    }

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) public view returns (Position memory) {
        bytes32 positionKey = PositionKey2.getPositionKey(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        );
        return positions[positionKey];
    }

    function sortTokens(
        address tokenA,
        address tokenB
    ) public pure returns (address token0, address token1) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function validatePositionPrice(
        uint160 _entryPrice,
        uint160 _takeProfitPrice,
        bool _isToken0Long
    ) public view {
        if (_isToken0Long) {
            if (_entryPrice > _takeProfitPrice) {
                revert InvalidPositionPrice(_entryPrice, _takeProfitPrice);
            }
        } else {
            if (_entryPrice < _takeProfitPrice) {
                revert InvalidPositionPrice(_entryPrice, _takeProfitPrice);
            }
        }
    }

    function isToken0Long(
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) public pure returns (bool) {
        return (_collateralToken < _indexToken) == _isLong;
    }

    function getEpoch(
        address _token0,
        address _token1,
        int24 _tickLower,
        bool _isLong
    ) public view returns (Epoch epoch) {
        IAlgebraPool pool = getPool(_token0, _token1);
        int24 _tickSpacing = pool.tickSpacing();
        epoch = limitOrderPlugin.getEpoch(
            address(pool),
            _tickLower,
            _tickLower + _tickSpacing,
            _isLong
        );
    }

    function _getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) private returns (Position storage) {
        bytes32 positionKey = PositionKey2.getPositionKey(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        );
        return positions[positionKey];
    }

    function _getPositionFromVault(
        address _user,
        address _collateralToken,
        address _indexToken
    ) private view returns (uint256 collateralValue, uint256 debtValue) {
        IVault vault = IVault(
            vaultFactory.vaults(_indexToken, _collateralToken)
        );
        (, collateralValue, debtValue) = vault.getPosition(_user);
    }

    function getEntryAndTakeProfitPrice(
        address _collateralToken,
        address _indexToken,
        int24 _tickLower
    ) public view returns (uint160 entryPrice, uint160 takeProfitPrice) {
        IAlgebraPool pool = getPool(_collateralToken, _indexToken);
        (entryPrice, , , , , , ) = pool.safelyGetStateOfAMM();
        takeProfitPrice = TickMath.getSqrtRatioAtTick(_tickLower);
    }

    function checkPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) public view returns (bool) {
        Position memory position = getPosition(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        );
        if (position.liquidity > 0) {
            return true;
        }
        return false;
    }
}
