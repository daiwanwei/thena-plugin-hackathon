// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@cryptoalgebra/integral-core/contracts/AlgebraFactory.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraPoolDeployer.sol";
import "@cryptoalgebra/integral-periphery/contracts/SwapRouter.sol";
import "@cryptoalgebra/integral-periphery/contracts/NonfungiblePositionManager.sol";
import "./BasePluginV1Factory.sol";
import "./LimitOrderPlugin.sol";

contract AlgebraDeployer {
    function deployPoolFactoryAndDeployer(
        address _poolDeployerAddress
    ) public returns (address poolFactoryAddress, address poolDeployerAddress) {
        AlgebraFactory _poolFactory = new AlgebraFactory(_poolDeployerAddress);
        poolFactoryAddress = address(_poolFactory);
        AlgebraPoolDeployer _poolDeployer = new AlgebraPoolDeployer(
            poolFactoryAddress,
            _poolFactory.communityVault()
        );
        poolDeployerAddress = address(_poolDeployer);
    }

    function deployPlugin(
        address _wNativeToken,
        address _poolFactory,
        address _poolDeployer
    )
        public
        returns (address pluginFactoryAddress, address limitOrderPluginAddress)
    {
        BasePluginV1Factory _pluginFactory = new BasePluginV1Factory(
            _poolFactory
        );
        LimitOrderPlugin _limitOrderPlugin = new LimitOrderPlugin(
            _wNativeToken,
            _poolDeployer,
            address(_pluginFactory),
            _poolFactory
        );
        _pluginFactory.setLimitOrderPlugin(address(_limitOrderPlugin));
        IAlgebraFactory(_poolFactory).setDefaultPluginFactory(
            address(_pluginFactory)
        );
        return (address(_pluginFactory), address(_limitOrderPlugin));
    }

    function deployPeriphery(
        address _wNativeToken,
        address _poolFactory,
        address _poolDeployer
    )
        public
        returns (
            address swapRouterAddress,
            address nonfungiblePositionManagerAddress
        )
    {
        SwapRouter swapRouter = new SwapRouter(
            _poolFactory,
            _wNativeToken,
            _poolDeployer
        );
        NonfungiblePositionManager nonfungiblePositionManager = new NonfungiblePositionManager(
                _poolFactory,
                _wNativeToken,
                address(0),
                _poolDeployer
            );
        return (address(swapRouter), address(nonfungiblePositionManager));
    }
}
