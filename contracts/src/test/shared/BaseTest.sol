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

contract BaseTest is Test {
    IAlgebraFactory public poolFactory;
    IAlgebraPoolDeployer public poolDeployer;
    BasePluginV1Factory public pluginFactory;
    IAlgebraPool public pool;
    SwapRouter public swapRouter;
    LimitOrderPlugin public limitOrderPlugin;
    NonfungiblePositionManager nonfungiblePositionManager;
    TestERC20 public token0;
    TestERC20 public token1;
    address public wNativeToken;
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    //    address public vault;

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
        ) = deployPoolFactory(owner);
        (
            address pluginFactoryAddress,
            address limitOrderPluginAddress
        ) = deployPlugin(owner, poolFactoryAddress, poolDeployerAddress);
        (address token0Address, address token1Address) = deployToken(owner);
        address poolAddress = initializePool(owner, 1 << 96);
        (
            address swapRouterAddress,
            address nftPositionManagerAddress
        ) = deployPeriphery(owner, poolFactoryAddress, poolDeployerAddress);
        addInitialLiquidity(owner);
    }

    function deployPoolFactory(
        address _user
    )
        public
        with(_user)
        returns (address poolDeployerAddress, address poolFactoryAddress)
    {
        uint64 nonce = vm.getNonce(owner);
        poolDeployerAddress = vm.computeCreateAddress(owner, nonce + 1);
        AlgebraFactory _poolFactory = new AlgebraFactory(poolDeployerAddress);
        AlgebraPoolDeployer _poolDeployer = new AlgebraPoolDeployer(
            address(_poolFactory),
            _poolFactory.communityVault()
        );
        assertEq(address(_poolDeployer), poolDeployerAddress);
        poolFactory = IAlgebraFactory(address(_poolFactory));
        poolDeployer = IAlgebraPoolDeployer(address(_poolDeployer));
        return (address(_poolDeployer), address(_poolFactory));
    }

    function deployPlugin(
        address _user,
        address _poolFactory,
        address _poolDeployer
    )
        public
        with(_user)
        returns (address pluginFactoryAddress, address limitOrderPluginAddress)
    {
        BasePluginV1Factory _pluginFactory = new BasePluginV1Factory(
            _poolFactory
        );
        LimitOrderPlugin _limitOrderPlugin = new LimitOrderPlugin(
            wNativeToken,
            _poolDeployer,
            address(_pluginFactory),
            _poolFactory
        );
        _pluginFactory.setLimitOrderPlugin(address(_limitOrderPlugin));
        IAlgebraFactory(_poolFactory).setDefaultPluginFactory(
            address(_pluginFactory)
        );
        pluginFactory = BasePluginV1Factory(address(_pluginFactory));
        limitOrderPlugin = LimitOrderPlugin(address(_limitOrderPlugin));
        return (address(_pluginFactory), address(_limitOrderPlugin));
    }

    function deployToken(
        address _user
    )
        public
        with(_user)
        returns (address token0Address, address token1Address)
    {
        TestERC20 tokenA = new TestERC20("USD Coin", "USDC", 100000000 ether);
        TestERC20 tokenB = new TestERC20("BNB", "BNB", 100000000 ether);
        tokenA.mint(_user, 100000000 ether);
        tokenB.mint(_user, 100000000 ether);
        (token0, token1) = address(tokenA) < address(tokenB)
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        return (address(token0), address(token1));
    }

    function deployPeriphery(
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
        swapRouter = new SwapRouter(_poolFactory, wNativeToken, _poolDeployer);
        nonfungiblePositionManager = new NonfungiblePositionManager(
            _poolFactory,
            wNativeToken,
            address(0),
            _poolDeployer
        );
        return (address(swapRouter), address(nonfungiblePositionManager));
    }

    function addInitialLiquidity(
        address _user
    )
        public
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        INonfungiblePositionManager.MintParams
            memory mintParams = INonfungiblePositionManager.MintParams({
                token0: address(token0),
                token1: address(token1),
                tickLower: -887220,
                tickUpper: 887220,
                amount0Desired: 1000000000000000000,
                amount1Desired: 1000000000000000000,
                amount0Min: 0,
                amount1Min: 0,
                recipient: _user,
                deadline: block.timestamp + 1000
            });
        (tokenId, liquidity, amount0, amount1) = mint(_user, mintParams);
    }

    function initializePool(
        address _user,
        uint160 initialPrice
    ) public with(_user) returns (address poolAddress) {
        poolAddress = poolFactory.createPool(address(token0), address(token1));
        pool = IAlgebraPool(poolAddress);
        pool.initialize(initialPrice);
    }

    function mint(
        address _user,
        INonfungiblePositionManager.MintParams memory _mintParams
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
        token0.approve(address(nonfungiblePositionManager), type(uint256).max);
        token1.approve(address(nonfungiblePositionManager), type(uint256).max);
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(_mintParams);
    }

    function swap(
        address _user,
        ISwapRouter.ExactInputSingleParams memory _swapParams
    ) public with(_user) returns (uint256 amountOut) {
        IERC20 tokenIn = IERC20(_swapParams.tokenIn);
        IERC20 tokenOut = IERC20(_swapParams.tokenOut);
        uint256 balanceInBefore = tokenIn.balanceOf(_user);
        uint256 balanceOutBefore = tokenOut.balanceOf(_user);
        tokenIn.approve(address(swapRouter), type(uint256).max);
        amountOut = swapRouter.exactInputSingle(_swapParams);
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