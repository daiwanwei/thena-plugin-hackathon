// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./interfaces/IVaultFactory.sol";
import "./interfaces/IPerpetual.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
contract PerpetualScript {
    function createVault(
        address _vaultFactory,
        address _asset,
        address _collateral,
        string memory _name,
        string memory _symbol
    ) public returns (address vaultAddress) {
        IVaultFactory vaultFactory = IVaultFactory(_vaultFactory);
        vaultAddress = vaultFactory.createVault(
            _name,
            _symbol,
            _asset,
            _collateral
        );
    }

    function depositToVault(
        address _vault,
        address _asset,
        address _receiver,
        uint256 _amount
    ) public {
        IERC20 token = IERC20(_asset);
        if (token.balanceOf(_receiver) < _amount) {
            revert("insufficient balance");
        }
        token.approve(_vault, _amount);
        IERC4626(_vault).deposit(_amount, _receiver);
    }

    function getVaultMetadata(
        address _asset
    ) public returns (string memory name, string memory symbol) {
        IERC20Metadata asset = IERC20Metadata(_asset);
        name = string.concat("Perpetual ", asset.name());
        symbol = string.concat("p", asset.symbol());
    }

    function increasePosition(
        address _perpetual,
        address _collateralToken,
        address _indexToken,
        int24 _tickLower,
        bool _isLong,
        uint256 _collateralAmount,
        uint256 _indexAmount
    ) public {
        IERC20Metadata collateralToken = IERC20Metadata(_collateralToken);
        collateralToken.approve(_perpetual, _collateralAmount);
        IPerpetual(_perpetual).increasePosition(
            IPerpetual.IncreasePositionParams({
                collateralToken: _collateralToken,
                indexToken: _indexToken,
                tickLower: _tickLower,
                isLong: _isLong,
                collateralAmount: _collateralAmount,
                indexAmount: _indexAmount
            })
        );
    }
}
