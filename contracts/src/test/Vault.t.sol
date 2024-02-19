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
    IVault public vault;
    IERC20 public collateralToken;
    IERC20 public indexToken;

    function setUp() public {
        collateralToken = token0;
        indexToken = token1;
        (string memory _name, string memory _symbol) = getVaultMetadata(
            address(indexToken)
        );
        vault = IVault(
            createVault(
                address(vaultFactory),
                address(indexToken),
                address(collateralToken),
                _name,
                _symbol
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

    function deposit(address _user, uint256 _amount) public with(_user) {
        if (indexToken.balanceOf(_user) < _amount) {
            revert("insufficient balance");
        }
        indexToken.approve(address(vault), _amount);
        IERC4626(address(vault)).deposit(_amount, _user);
    }

    function totalAssets() public view returns (uint256) {
        return IERC4626(address(vault)).totalAssets();
    }

    function test_PrintPrice() public {
        uint256 price=1<<96;
        console2.log("price: %s",price);
    }
}
