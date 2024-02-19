// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Vault.sol";
import "./interfaces/IVaultFactory.sol";
import {IAlgebraFactory} from "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraFactory.sol";
import {IAlgebraPool} from "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraPool.sol";
import {ISwapRouter} from "@cryptoalgebra/integral-periphery/contracts/interfaces/ISwapRouter.sol";

contract VaultFactory is IVaultFactory {
    mapping(address => mapping(address => address)) public vaults;
    IAlgebraFactory public poolFactory;
    ISwapRouter public swapRouter;

    constructor(address _factory, address _swapRouter) {
        poolFactory = IAlgebraFactory(_factory);
        swapRouter = ISwapRouter(_swapRouter);
    }

    function createVault(
        string memory _name,
        string memory _symbol,
        address _asset,
        address _collateral
    ) public returns (address vaultAddress) {
        if (vaults[_asset][_collateral] != address(0)) {
            revert VaultAlreadyExists();
        }
        address pool = poolFactory.poolByPair(_asset, _collateral);
        vaultAddress = address(
            new Vault(
                _name,
                _symbol,
                IERC20(_asset),
                IERC20(_collateral),
                IAlgebraPool(pool),
                swapRouter
            )
        );
        vaults[_asset][_collateral] = vaultAddress;
    }
}
