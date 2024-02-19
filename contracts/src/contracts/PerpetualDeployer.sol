// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./VaultFactory.sol";
import "./Perpetual.sol";

contract PerpetualDeployer {
    function deployVaultFactoryAndPerpetual(
        address _poolFactory,
        address _swapRouter,
        address _limitOrderPlugin
    ) public returns (address vaultFactoryAddress, address perpetualAddress) {
        VaultFactory vaultFactory = new VaultFactory(_poolFactory, _swapRouter);
        Perpetual perpetual = new Perpetual(
            _poolFactory,
            _limitOrderPlugin,
            _swapRouter,
            address(vaultFactory)
        );
        vaultFactoryAddress = address(vaultFactory);
        perpetualAddress = address(perpetual);
    }
}
