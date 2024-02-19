// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BaseTest} from "./shared/BaseTest.sol";
import {ISwapRouter} from "@cryptoalgebra/integral-periphery/contracts/interfaces/ISwapRouter.sol";
import {PoolAddress} from "@cryptoalgebra/integral-periphery/contracts/libraries/PoolAddress.sol";
import {TickMath} from "@cryptoalgebra/integral-core/contracts/libraries/TickMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/Perpetual.sol";
import {IPerpetual} from "../contracts/interfaces/IPerpetual.sol";
import {Epoch} from "../contracts/libraries/EpochLibrary.sol";
import "../contracts/VaultFactory.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract PerpetualTest is BaseTest {
    IVault public vault;
    IERC20 public collateralToken;
    IERC20 public indexToken;
    function setUp() public {
        collateralToken = token0;
        indexToken = token1;
        (string memory _name, string memory _symbol) = getVaultMetadata(
            address(indexToken)
        );
        vault = IVault(
            createVault(
                address(vaultFactory),
                address(indexToken),
                address(collateralToken),
                _name,
                _symbol
            )
        );
        depositToVault(owner, 1 ether);
    }

    function test_OpenPosition() public {
        int24 tickSpacing = pool.tickSpacing();
        IPerpetual.IncreasePositionParams memory _params = IPerpetual
            .IncreasePositionParams({
                collateralToken: address(collateralToken),
                indexToken: address(indexToken),
                tickLower: tickSpacing,
                isLong: true,
                collateralAmount: 1000,
                indexAmount: 10000
            });
        increasePosition(owner, _params);
    }

    function test_ClosePosition() public {
        int24 tickSpacing = pool.tickSpacing();
        console2.log("before opening position");
        printBalances(owner);
        IPerpetual.IncreasePositionParams memory _params = IPerpetual
            .IncreasePositionParams({
                collateralToken: address(collateralToken),
                indexToken: address(indexToken),
                tickLower: tickSpacing,
                isLong: true,
                collateralAmount: 1000,
                indexAmount: 10000
            });
        increasePosition(owner, _params);
        console2.log("after opening position");
        printBalances(owner);
        console2.log("before swapping");
        swap(
            owner,
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(indexToken),
                tokenOut: address(collateralToken),
                recipient: owner,
                deadline: block.timestamp + 1000,
                amountIn: 100 ether,
                amountOutMinimum: 0,
                limitSqrtPrice: TickMath.MAX_SQRT_RATIO - 1
            })
        );
        console2.log("after swapping");
        printBalances(owner);
        console2.log("before close position");
        IPerpetual.DecreasePositionParams memory closeParams = IPerpetual
            .DecreasePositionParams({
                collateralToken: address(collateralToken),
                indexToken: address(indexToken),
                isLong: true
            });

        decreasePosition(owner, closeParams);
        console2.log("after close Position");
        printBalances(owner);
    }

    function increasePosition(
        address _user,
        IPerpetual.IncreasePositionParams memory _params
    ) public with(_user) {
        IPerpetual.Position memory positionBefore = perpetual.getPosition(
            _user,
            _params.collateralToken,
            _params.indexToken,
            _params.isLong
        );
        IERC20(_params.collateralToken).approve(
            address(perpetual),
            _params.collateralAmount
        );
        (uint128 liquidityDelta, uint256 sizeDelta) = perpetual
            .increasePosition(_params);
        IPerpetual.Position memory positionAfter = perpetual.getPosition(
            _user,
            _params.collateralToken,
            _params.indexToken,
            _params.isLong
        );
        assertEq(
            positionAfter.collateralAmount - positionBefore.collateralAmount,
            _params.collateralAmount
        );
        assertEq(positionAfter.debt - positionBefore.debt, _params.indexAmount);
        assertEq(
            liquidityDelta,
            positionAfter.liquidity - positionBefore.liquidity
        );
        assertEq(sizeDelta, positionAfter.size - positionBefore.size);
    }

    function decreasePosition(
        address _user,
        IPerpetual.DecreasePositionParams memory _params
    ) public with(_user) {
        IPerpetual.Position memory positionBefore = perpetual.getPosition(
            _user,
            _params.collateralToken,
            _params.indexToken,
            _params.isLong
        );
        (uint128 liquidityDelta, uint256 sizeDelta) = perpetual
            .decreasePosition(_params);
        IPerpetual.Position memory positionAfter = perpetual.getPosition(
            _user,
            _params.collateralToken,
            _params.indexToken,
            _params.isLong
        );
        assertEq(positionAfter.collateralAmount, 0);
        assertEq(positionAfter.debt, 0);
        assertEq(
            liquidityDelta,
            positionBefore.liquidity - positionAfter.liquidity
        );
        assertEq(sizeDelta, positionBefore.size - positionAfter.size);
    }

    function depositToVault(address _user, uint256 _amount) public with(_user) {
        depositToVault(address(vault), address(indexToken), _user, _amount);
    }
}
