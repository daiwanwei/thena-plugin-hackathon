// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BaseTest} from "./shared/BaseTest.sol";
import {ISwapRouter} from "@cryptoalgebra/integral-periphery/contracts/interfaces/ISwapRouter.sol";
import {PoolAddress} from "@cryptoalgebra/integral-periphery/contracts/libraries/PoolAddress.sol";
import {TickMath} from "@cryptoalgebra/integral-core/contracts/libraries/TickMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolTest is BaseTest {
    function setUp() public {}

    function test_Swap() public {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(token0),
                tokenOut: address(token1),
                recipient: owner,
                deadline: block.timestamp + 1000,
                amountIn: 1000,
                amountOutMinimum: 0,
                limitSqrtPrice: 0
            });
        swapToken(owner, params);
    }

    function test_PlaceOrder() public {
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({
            token0: address(token0),
            token1: address(token1)
        });
        int24 tickSpacing = pool.tickSpacing();
        console2.log("tickSpacing: %s", tickSpacing);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool
            .safelyGetStateOfAMM();
        console2.log("sqrtPriceX96: %s", sqrtPriceX96);
        console2.log("tick: %s", tick);
        placeOrder(owner, poolKey, tick + tickSpacing, true, 1000);
    }

    function placeOrder(
        address _user,
        PoolAddress.PoolKey memory poolKey,
        int24 tickLower,
        bool zeroForOne,
        uint128 liquidity
    ) public with(_user) {
        IERC20 token0 = IERC20(poolKey.token0);
        IERC20 token1 = IERC20(poolKey.token1);
        token0.approve(address(limitOrderPlugin), type(uint256).max);
        token1.approve(address(limitOrderPlugin), type(uint256).max);
        limitOrderPlugin.place(poolKey, tickLower, zeroForOne, liquidity);
    }
}
