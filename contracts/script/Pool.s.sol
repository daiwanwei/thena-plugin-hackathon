// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/contracts/mocks/TestERC20.sol";
import "../src/contracts/VaultFactory.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraFactory.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraPoolDeployer.sol";
import {AlgebraScript} from "../src/contracts/AlgebraScript.sol";

contract PoolScript is Script, AlgebraScript {
    function createAndInitializePool(
        address _poolFactory,
        address _token0,
        address _token1,
        uint160 _initialPrice
    ) public returns (address poolAddress) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        poolAddress = createPool(_poolFactory, _token0, _token1, _initialPrice);
    }

    function initializeLiquidity(
        address _positionManager,
        address _token0,
        address _token1
    ) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        mintPosition(
            _positionManager,
            _token0,
            _token1,
            10000000000 ether,
            10000000000 ether,
            60 * -100,
            60 * 100,
            vm.addr(deployerPrivateKey)
        );
    }

    function increaseLiquidityToPool(
        address _positionManager,
        uint256 tokenId,
        address _token0,
        address _token1
    ) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        increaseLiquidity(
            _positionManager,
            tokenId,
            _token0,
            _token1,
            10000000000 ether,
            10000000000 ether,
            0,
            0
        );
    }
}
