// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BaseTest} from "./shared/BaseTest.sol";
import {ISwapRouter} from "@cryptoalgebra/integral-periphery/contracts/interfaces/ISwapRouter.sol";
import {PoolAddress} from "@cryptoalgebra/integral-periphery/contracts/libraries/PoolAddress.sol";
import {TickMath} from "@cryptoalgebra/integral-core/contracts/libraries/TickMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/Perpetual.sol";
import {Epoch} from "../contracts/libraries/EpochLibrary.sol";
import "../contracts/Vault.sol";
import "../contracts/VaultFactory.sol";
import "../contracts/interfaces/IVault.sol";
import "../contracts/interfaces/IVaultFactory.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract VaultTest is BaseTest {
    IVaultFactory public vaultFactory;
    IVault public vault;
    IERC20 public collateralToken;
    IERC20 public indexToken;

    function setUp() public {
        vaultFactory = new VaultFactory(poolFactory, swapRouter);
        collateralToken = token0;
        indexToken = token1;
        vault = IVault(
            vaultFactory.createVault(
                "TestVault",
                "TV",
                address(indexToken),
                address(collateralToken)
            )
        );
    }

    function testFuzz_Deposit(uint256 _amount) public {
        vm.assume(_amount <= indexToken.balanceOf(owner));
        uint256 vaultAssetBefore = totalAssets();
        deposit(owner, _amount);
        uint256 vaultAssetAfter = totalAssets();
        assertEq(vaultAssetAfter, vaultAssetBefore + _amount);
    }

    //    function testFuzz_IncreasePosition(uint256 _collateral ,uint256 _size) public {
    //        vm.assume(_size <= indexToken.balanceOf(owner));
    //        deposit(owner, _size);
    //        vm.assume(_collateral <= collateralToken.balanceOf(owner));
    //        vm.assume(_size <= indexToken.balanceOf(address(vault)));
    //        IVault.IncreasePositionParams memory params = IVault.IncreasePositionParams({
    //            collateralDelta: _collateral,
    //            debtDelta: _size,
    //            user: owner
    //        });
    //        increasePosition(owner, params);
    //    }

    function test_IncreasePosition() public {
        uint256 _collateral = 1000;
        uint256 _size = 10000;
        console2.log("collateral: %s", collateralToken.balanceOf(owner));
        deposit(owner, _size * 1000000000000000);
        //        vm.assume(_collateral <= collateralToken.balanceOf(owner));
        //        vm.assume(_size <= indexToken.balanceOf(address(vault)));
        IVault.IncreasePositionParams memory params = IVault
            .IncreasePositionParams({
                collateralDelta: _collateral,
                debtDelta: _size,
                user: owner,
                recipient: owner
            });
        printBalances(owner);
        increasePosition(owner, params);
        printBalances(owner);
        vault.checkHealth(owner);
    }

    function deposit(address _user, uint256 _amount) public with(_user) {
        if (indexToken.balanceOf(_user) < _amount) {
            revert("insufficient balance");
        }
        indexToken.approve(address(vault), _amount);
        IERC4626(address(vault)).deposit(_amount, _user);
    }

    function increasePosition(
        address _user,
        IVault.IncreasePositionParams memory _params
    ) public with(_user) {
        if (collateralToken.balanceOf(_user) < _params.collateralDelta) {
            revert("insufficient balance");
        }
        collateralToken.approve(address(vault), _params.collateralDelta);
        vault.increasePosition(_params);
        (, uint256 collateral, uint256 size) = vault.getPosition(_user);
        console2.log("position size: %s,collateral: %s", size, collateral);
    }

    function totalAssets() public view returns (uint256) {
        return IERC4626(address(vault)).totalAssets();
    }
}
