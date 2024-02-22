// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IVault {
    struct IncreasePositionParams {
        address user;
        address recipient;
        uint256 collateralDelta;
        uint256 debtDelta;
    }

    struct DecreasePositionParams {
        address payer;
        address user;
        uint256 collateralDelta;
        uint256 debtDelta;
    }

    struct KillPositionParams {
        address payer;
        address user;
        uint256 debtDelta;
    }

    struct Position {
        uint256 price;
        uint256 collateral;
        uint256 debt;
    }

    function increasePosition(IncreasePositionParams calldata params) external;

    function decreasePosition(DecreasePositionParams calldata params) external;

    function killPosition(KillPositionParams memory _params) external returns (uint256 collateralForRefund);

    function totalDebt() external view returns (uint256);

    function assetBalance() external view returns (uint256);

    function getPosition(
        address _user
    ) external view returns (uint256 price, uint256 collateral, uint256 debt);

    function checkHealth(address _user) external view returns (bool);
}
