// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/contracts/mocks/TestERC20.sol";
import "../src/contracts/VaultFactory.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraFactory.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraPoolDeployer.sol";
import {AlgebraScript} from "../src/contracts/AlgebraScript.sol";
import {PerpetualScript} from "../src/contracts/PerpetualScript.sol";

contract PerpScript is Script, AlgebraScript, PerpetualScript {
    function createAndInitializeVault(
        address _vaultFactory,
        address _asset,
        address _collateral,
        uint256 _amount
    ) public returns (address vaultAddress) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployer = vm.addr(deployerPrivateKey);
        (string memory name, string memory symbol) = getVaultMetadata(_asset);
        vaultAddress = createVault(
            _vaultFactory,
            _asset,
            _collateral,
            name,
            symbol
        );
        depositToVault(vaultAddress, _asset, deployer, 100000000 ether);
        vm.label(vaultAddress, "Vault");
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

    function openPosition(
        address _perpetual,
        address _collateral,
        address _index,
        int24 _tickLower,
        //        bool _isLong,
        uint256 _collateralAmount,
        uint256 _indexAmount
    ) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        uint160 takeProfitPrice = TickMath.getSqrtRatioAtTick(_tickLower);
        console2.log("takeProfitPrice: %s", takeProfitPrice);
        increasePosition(
            _perpetual,
            _collateral,
            _index,
            takeProfitPrice,
            true,
            _collateralAmount,
            _indexAmount
        );
    }
}
