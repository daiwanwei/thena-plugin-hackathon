// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/contracts/mocks/TestERC20.sol";
import "../src/contracts/VaultFactory.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraFactory.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraPoolDeployer.sol";
import "../src/contracts/AlgebraDeployer.sol";
import {PerpetualDeployer} from "../src/contracts/PerpetualDeployer.sol";

contract DeploymentScript is Script, AlgebraDeployer, PerpetualDeployer {
    function deployTokens() public returns (address token0, address token1) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        TestERC20 tokenB = new TestERC20(
            "WBNB",
            "WBNB",
            10000000000000000000000000 ether
        );
        TestERC20 tokenA = new TestERC20(
            "USDC",
            "USDC",
            10000000000000000000000000 ether
        );
        vm.label(address(tokenA), "USDC");
        vm.label(address(tokenB), "BNB");
        token0 = address(tokenA) < address(tokenB)
            ? address(tokenA)
            : address(tokenB);
        token1 = address(tokenA) > address(tokenB)
            ? address(tokenA)
            : address(tokenB);
    }

    function deployAlgebraContracts()
        public
        returns (
            address poolFactoryAddress,
            address poolDeployerAddress,
            address pluginFactoryAddress,
            address limitOrderPluginAddress,
            address swapRouterAddress,
            address nftPositionManagerAddress
        )
    {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address _deployer = vm.addr(deployerPrivateKey);
        uint64 _nonce = vm.getNonce(_deployer);
        address wNativeToken = address(0);
        poolDeployerAddress = vm.computeCreateAddress(_deployer, _nonce + 1);
        (
            poolFactoryAddress,
            poolDeployerAddress
        ) = deployPoolFactoryAndDeployer(poolDeployerAddress);
        vm.label(poolFactoryAddress, "poolFactory");
        vm.label(poolDeployerAddress, "poolDeployer");
        (pluginFactoryAddress, limitOrderPluginAddress) = deployPlugin(
            wNativeToken,
            poolFactoryAddress,
            poolDeployerAddress
        );
        vm.label(pluginFactoryAddress, "pluginFactory");
        vm.label(limitOrderPluginAddress, "limitOrderPlugin");
        (swapRouterAddress, nftPositionManagerAddress) = deployPeriphery(
            wNativeToken,
            poolFactoryAddress,
            poolDeployerAddress
        );
        vm.label(swapRouterAddress, "swapRouter");
        vm.label(nftPositionManagerAddress, "nftPositionManager");
    }

    function deployPerpetualContracts(
        address _poolFactory,
        address _swapRouter,
        address _limitOrderPlugin
    ) public returns (address vaultFactoryAddress, address perpetualAddress) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address _deployer = vm.addr(deployerPrivateKey);
        (
            vaultFactoryAddress,
            perpetualAddress
        ) = deployVaultFactoryAndPerpetual(
            _poolFactory,
            _swapRouter,
            _limitOrderPlugin
        );
        vm.label(perpetualAddress, "perpetual");
        vm.label(vaultFactoryAddress, "vaultFactory");
    }
}
