// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@cryptoalgebra/integral-core/contracts/AlgebraFactory.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraPoolDeployer.sol";
import "@cryptoalgebra/integral-periphery/contracts/SwapRouter.sol";
import "@cryptoalgebra/integral-periphery/contracts/NonfungiblePositionManager.sol";
import "./BasePluginV1Factory.sol";
import "./LimitOrderPlugin.sol";

contract AlgebraScript {
    function createPool(
        address _poolFactory,
        address token0,
        address token1,
        uint160 initialPrice
    ) public returns (address poolAddress) {
        poolAddress = IAlgebraFactory(_poolFactory).createPool(token0, token1);
        IAlgebraPool(poolAddress).initialize(initialPrice);
    }

    function mintPosition(
        address _positionManager,
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1,
        int24 _tickLower,
        int24 _tickUpper,
        address _user
    )
        public
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        INonfungiblePositionManager.MintParams
            memory _mintParams = INonfungiblePositionManager.MintParams({
                token0: _token0,
                token1: _token1,
                tickLower: _tickLower,
                tickUpper: _tickUpper,
                amount0Desired: _amount0,
                amount1Desired: _amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: _user,
                deadline: block.timestamp + 1000
            });
        IERC20(_token0).approve(address(_positionManager), _amount0);
        IERC20(_token1).approve(address(_positionManager), _amount1);
        (tokenId, liquidity, amount0, amount1) = INonfungiblePositionManager(
            _positionManager
        ).mint(_mintParams);
    }
}
