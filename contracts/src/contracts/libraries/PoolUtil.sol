// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {FullMath} from "@cryptoalgebra/integral-core/contracts/libraries/FullMath.sol";
import {Constants} from "@cryptoalgebra/integral-core/contracts/libraries/Constants.sol";
import {IAlgebraPool} from "@cryptoalgebra/integral-core/contracts/interfaces/IAlgebraPool.sol";

library PoolUtil {
    function getPoolPrice(
        IAlgebraPool _pool
    ) internal view returns (uint256 price) {
        (uint256 sqrtPrice, , , , , , ) = _pool.safelyGetStateOfAMM();
        price =
            FullMath.mulDiv(sqrtPrice, sqrtPrice, Constants.Q96) /
            (Constants.Q96);
    }
}
