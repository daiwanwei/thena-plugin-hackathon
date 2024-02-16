// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVaultFactory {
    error VaultAlreadyExists();

    function createVault(
        string memory _name,
        string memory _symbol,
        address _asset,
        address _collateral
    ) external returns (address vaultAddress);

    function vaults(
        address _asset,
        address _collateral
    ) external view returns (address);
}
