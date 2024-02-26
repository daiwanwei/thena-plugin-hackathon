// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IVault} from "./interfaces/IVault.sol";
import "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraPool.sol";
import {ISwapRouter} from "@cryptoalgebra/integral-periphery/contracts/interfaces/ISwapRouter.sol";
import {console2} from "forge-std/Test.sol";
import {TickMath} from "@cryptoalgebra/integral-core/contracts/libraries/TickMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {PoolUtil} from "./libraries/PoolUtil.sol";

contract Vault is ERC4626, IVault {
    using Math for uint256;

    IERC20 public collateralToken;
    IAlgebraPool public pool;
    ISwapRouter public swapRouter;
    uint256 public totalCollateral;
    uint256 public totalDebt;

    mapping(address => Position) public positions;

    error InsufficientBalance();

    event Borrow(
        address indexed borrower,
        address indexed receiver,
        uint256 amount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        IERC20 _asset,
        IERC20 _collateralToken,
        IAlgebraPool _pool,
        ISwapRouter _swapRouter
    ) ERC4626(_asset) ERC20(_name, _symbol) {
        collateralToken = _collateralToken;
        pool = _pool;
        swapRouter = _swapRouter;
    }

    function increasePosition(IncreasePositionParams memory _params) public {
        if (assetBalance() < _params.debtDelta) {
            revert InsufficientBalance();
        }
        _pay(_msgSender(), _params.user, _params.collateralDelta);
        _borrow(_params.user, _params.recipient, _params.debtDelta);
    }

    function decreasePosition(DecreasePositionParams memory _params) public {
        Position memory position = positions[_params.user];
        if (position.collateral < _params.collateralDelta) {
            revert InsufficientBalance();
        }
        _refund(_params.user, _params.user, _params.collateralDelta);
        _repay(_params.payer, _params.user, _params.debtDelta);
    }

    function killPosition(
        KillPositionParams memory _params
    ) public returns (uint256 collateralForRefund) {
        Position memory position = positions[_params.user];
        if (position.debt < _params.debtDelta) {
            revert("InvalidDebtDelta");
        }
        uint256 debtForLiquidation = position.debt - _params.debtDelta;
        _repay(_params.payer, _params.user, _params.debtDelta);
        if (debtForLiquidation > 0) {
            uint256 collateralDelta = _liquidate(
                _params.user,
                debtForLiquidation
            );
            collateralForRefund = position.collateral - collateralDelta;
            _refund(_params.user, _params.user, collateralForRefund);
        } else {
            collateralForRefund = position.collateral;
            _refund(_params.user, _params.user, collateralForRefund);
        }
        if (collateralForRefund < 0) {
            revert("invalid collateral for refund");
            //            revert InsufficientBalance();
        }
    }

    function _pay(address _payer, address _suppler, uint256 _amount) private {
        if (collateralToken.balanceOf(_payer) < _amount) {
            revert InsufficientBalance();
        }
        collateralToken.transferFrom(_payer, address(this), _amount);
        Position storage position = positions[_suppler];
        position.collateral += _amount;
        totalCollateral += _amount;
    }

    function _borrow(
        address _borrower,
        address _recipient,
        uint256 _amount
    ) private {
        IERC20 _asset = IERC20(asset());
        if (_asset.balanceOf(address(this)) < _amount) {
            revert InsufficientBalance();
        }
        _asset.transfer(_recipient, _amount);
        Position storage position = positions[_borrower];
        position.debt += _amount;
        totalDebt += _amount;
    }

    function _repay(
        address _payer,
        address _borrower,
        uint256 _amount
    ) private {
        Position storage position = positions[_borrower];
        IERC20 _asset = IERC20(asset());
        if (_asset.balanceOf(_payer) < _amount) {
            revert InsufficientBalance();
        }
        _asset.transferFrom(_payer, address(this), _amount);
        position.debt -= _amount;
        totalDebt -= _amount;
    }

    function _refund(
        address _borrower,
        address _recipient,
        uint256 _amount
    ) private {
        Position storage position = positions[_borrower];
        if (collateralToken.balanceOf(address(this)) < _amount) {
            revert InsufficientBalance();
        }
        console2.log("refund amount: %s", _amount);
        collateralToken.transfer(_recipient, _amount);
        position.collateral -= _amount;
        totalCollateral -= _amount;
    }

    function _liquidate(
        address _borrower,
        uint256 _debtDelta
    ) private returns (uint256 collateralDelta) {
        Position storage position = positions[_borrower];
        if (position.debt < _debtDelta) {
            revert InsufficientBalance();
        }
        collateralToken.approve(address(swapRouter), type(uint256).max);
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: address(collateralToken),
                tokenOut: address(asset()),
                recipient: address(this),
                deadline: block.timestamp + 60,
                amountOut: _debtDelta,
                amountInMaximum: type(uint256).max,
                limitSqrtPrice: 0
            });

        collateralDelta = swapRouter.exactOutputSingle(params);
        position.debt -= _debtDelta;
        totalDebt -= _debtDelta;
        position.collateral -= collateralDelta;
        totalCollateral -= collateralDelta;
    }

    function totalAssets() public view override returns (uint256) {
        IERC20 _asset = IERC20(asset());
        return _asset.balanceOf(address(this)) + totalDebt;
    }

    function assetBalance() public view returns (uint256) {
        IERC20 _asset = IERC20(asset());
        return _asset.balanceOf(address(this));
    }

    function checkHealth(address _user) public view returns (bool isHealthy) {
        Position memory position = positions[_user];
        uint256 price = PoolUtil.getPoolPrice(pool);
        uint256 priceDelta = 0;
        uint256 debtValueDelta = 0;
        if (asset() < address(collateralToken)) {
            if (position.price > price) {
                return true;
            }
            priceDelta = price - position.price;
            debtValueDelta = position.debt / priceDelta;
        } else {
            if (position.price < price) {
                return true;
            }
            priceDelta = position.price - price;
            debtValueDelta = position.debt * priceDelta;
        }
        isHealthy = position.collateral.mulDiv(950, 1000) > debtValueDelta;
    }

    function getPosition(
        address _user
    )
        public
        view
        override
        returns (uint256 price, uint256 collateral, uint256 debt)
    {
        Position memory position = positions[_user];
        price = position.price;
        collateral = position.collateral;
        debt = position.debt;
    }
}
