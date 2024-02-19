// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/contracts/mocks/TestERC20.sol";
import "../src/contracts/VaultFactory.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraFactory.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraPoolDeployer.sol";
import {AlgebraScript} from "../src/contracts/AlgebraScript.sol";
import {PerpetualScript} from "../src/contracts/PerpetualScript.sol";

contract PerpScript is Script, AlgebraScript,PerpetualScript {
    function createAndInitializeVault(
        address _vaultFactory,
        address _asset,
        address _collateral,
        uint256 _amount
    ) public returns (address vaultAddress) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployer=vm.addr(deployerPrivateKey);
        (string memory name, string memory symbol) = getVaultMetadata(_asset);
        vaultAddress= createVault(_vaultFactory, _asset, _collateral,name,symbol);
        depositToVault(vaultAddress, _asset, deployer, _amount);
    }

    function depositAssetToVault(
        address _vault,
        address _asset,
        address _receiver,
        uint256 _amount
    ) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        depositToVault(_vault, _asset, _receiver, _amount);
    }
}
