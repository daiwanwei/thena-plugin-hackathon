// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraFactory.sol";
import "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraPool.sol";
import "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraPoolDeployer.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraPoolDeployer.sol";
import "@cryptoalgebra/integral-core/contracts/AlgebraFactory.sol";
import "@cryptoalgebra/integral-periphery/contracts/SwapRouter.sol";

import "../../contracts/BasePluginV1Factory.sol";
import "../../contracts/LimitOrderPlugin.sol";
import "../../contracts/mocks/TestERC20.sol";
import "@cryptoalgebra/integral-periphery/contracts/NonfungiblePositionManager.sol";
import {AlgebraDeployer} from "../../contracts/AlgebraDeployer.sol";
import "../../contracts/AlgebraScript.sol";
import "../../contracts/PerpetualDeployer.sol";
import "../../contracts/interfaces/IPerpetual.sol";
import "../../contracts/interfaces/IVaultFactory.sol";
import {PerpetualScript} from "../../contracts/PerpetualScript.sol";

contract BaseTest is
    Test,
    AlgebraDeployer,
    AlgebraScript,
    PerpetualDeployer,
    PerpetualScript
{
    IAlgebraFactory public poolFactory;
    IAlgebraPoolDeployer public poolDeployer;
    BasePluginV1Factory public pluginFactory;
    IAlgebraPool public pool;
    SwapRouter public swapRouter;
    LimitOrderPlugin public limitOrderPlugin;
    NonfungiblePositionManager nonfungiblePositionManager;
    IPerpetual public perpetual;
    IVaultFactory public vaultFactory;
    TestERC20 public token0;
    TestERC20 public token1;
    address public wNativeToken;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    modifier with(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }

    constructor() {
        owner = address(0x1);
        user1 = address(0x2);
        user2 = address(0x3);
        user3 = address(0x4);
        wNativeToken = address(0);
        (
            address poolDeployerAddress,
            address poolFactoryAddress
        ) = setupPoolFactory(owner);
        (
            address pluginFactoryAddress,
            address limitOrderPluginAddress
        ) = setupPlugin(owner, poolFactoryAddress, poolDeployerAddress);
        (address token0Address, address token1Address) = setupToken(owner);
        address poolAddress = setupPool(owner, 1 << 96);
        (
            address swapRouterAddress,
            address nftPositionManagerAddress
        ) = setupPeriphery(owner, poolFactoryAddress, poolDeployerAddress);
        setupInitialLiquidity(owner);
        (
            address _vaultFactory,
            address _perpetual
        ) = deployVaultFactoryAndPerpetual(
                address(poolFactory),
                address(swapRouter),
                address(limitOrderPlugin)
            );
        vaultFactory = IVaultFactory(_vaultFactory);
        perpetual = IPerpetual(_perpetual);
    }

    function setupPoolFactory(
        address _user
    )
        public
        with(_user)
        returns (address poolDeployerAddress, address poolFactoryAddress)
    {
        uint64 nonce = vm.getNonce(owner);
        address _poolDeployerAddress = vm.computeCreateAddress(
            owner,
            nonce + 1
        );
        (
            poolFactoryAddress,
            poolDeployerAddress
        ) = deployPoolFactoryAndDeployer(_poolDeployerAddress);
        assertEq(poolDeployerAddress, _poolDeployerAddress);
        poolFactory = IAlgebraFactory(poolFactoryAddress);
        poolDeployer = IAlgebraPoolDeployer(poolDeployerAddress);
    }

    function setupPlugin(
        address _user,
        address _poolFactory,
        address _poolDeployer
    )
        public
        with(_user)
        returns (address pluginFactoryAddress, address limitOrderPluginAddress)
    {
        (pluginFactoryAddress, limitOrderPluginAddress) = deployPlugin(
            wNativeToken,
            _poolFactory,
            _poolDeployer
        );
        pluginFactory = BasePluginV1Factory(pluginFactoryAddress);
        limitOrderPlugin = LimitOrderPlugin(limitOrderPluginAddress);
    }

    function setupToken(
        address _user
    )
        public
        with(_user)
        returns (address token0Address, address token1Address)
    {
        TestERC20 tokenA = new TestERC20(
            "USD Coin",
            "USDC",
            100000000000000 ether
        );
        TestERC20 tokenB = new TestERC20("BNB", "BNB", 100000000000000 ether);
        tokenA.mint(_user, 10000000000000000000000000 ether);
        tokenB.mint(_user, 10000000000000000000000000 ether);
        (token0, token1) = address(tokenA) < address(tokenB)
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        return (address(token0), address(token1));
    }

    function setupPeriphery(
        address _user,
        address _poolFactory,
        address _poolDeployer
    )
        public
        with(_user)
        returns (
            address swapRouterAddress,
            address nonfungiblePositionManagerAddress
        )
    {
        (
            swapRouterAddress,
            nonfungiblePositionManagerAddress
        ) = deployPeriphery(wNativeToken, _poolFactory, _poolDeployer);
        swapRouter = SwapRouter(payable(swapRouterAddress));
        nonfungiblePositionManager = NonfungiblePositionManager(
            payable(nonfungiblePositionManagerAddress)
        );
    }

    function setupInitialLiquidity(
        address _user
    )
        public
        with(_user)
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        return
            mintPosition(
                address(nonfungiblePositionManager),
                address(token0),
                address(token1),
                10000000000 ether,
                10000000000 ether,
                60 * -100,
                60 * 100,
                _user
            );
    }

    function setupPool(
        address _user,
        uint160 initialPrice
    ) public with(_user) returns (address poolAddress) {
        poolAddress = createPool(
            address(poolFactory),
            address(token0),
            address(token1),
            initialPrice
        );
        pool = IAlgebraPool(poolAddress);
    }

    function swapToken(
        address _user,
        ISwapRouter.ExactInputSingleParams memory _swapParams
    ) public with(_user) returns (uint256 amountOut) {
        IERC20 tokenIn = IERC20(_swapParams.tokenIn);
        IERC20 tokenOut = IERC20(_swapParams.tokenOut);
        uint256 balanceInBefore = tokenIn.balanceOf(_user);
        uint256 balanceOutBefore = tokenOut.balanceOf(_user);
        amountOut = swap(address(swapRouter), _swapParams);
        uint256 balanceInAfter = tokenIn.balanceOf(_user);
        uint256 balanceOutAfter = tokenOut.balanceOf(_user);
        assertEq(balanceInBefore - balanceInAfter, _swapParams.amountIn);
        assertEq(balanceOutAfter - balanceOutBefore, amountOut);
    }

    function printBalances(address _user) public {
        console2.log(
            "user(%s): Balance0[%s:(%s)]",
            _user,
            address(token0),
            token0.balanceOf(_user)
        );

        console2.log(
            "user(%s): Balance1[%s:(%s)]",
            _user,
            address(token1),
            token1.balanceOf(_user)
        );
    }
}
