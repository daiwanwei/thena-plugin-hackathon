import BigNumber from "bignumber.js";
import { Decimal } from 'decimal.js';
import {TickMath} from "@uniswap/v3-sdk";
export function formatBalances(balances: string, decimals: number, fixed=2): string {
  return BigNumber(balances)
      .dividedBy(BigNumber(10 ** decimals))
      .toFixed(fixed);
}

export function formatAmount(amount: string, decimals: number): string {
    return BigNumber(amount)
        .multipliedBy(BigNumber(10 ** decimals))
        .toFixed(0);
}

export function formatPrice(priceSqrt: bigint,isToken0Price = true,fixed=2): string {
    if (priceSqrt === BigInt(0)) {
        return "0";
    }
   const price0=new Decimal(priceSqrt.toString(10)).pow(2).dividedBy(new Decimal(2).pow(192)).toPrecision(fixed);
   const price1=(new Decimal(1).dividedBy(price0)).toPrecision(fixed);
   return isToken0Price?price0:price1;
}

export function encodePriceSqrt(price:BigNumber): bigint {
    return BigInt(
        price.sqrt()
            .multipliedBy(new BigNumber(2).pow(96))
            .integerValue()
            .toString(10)
    );
}

export function proximalPriceSqrt(targetSqrt: bigint, tick0:number=-887272,tick1:number=887272,tickSpacing:number=60): bigint {
    if (tick0 > tick1) {
        throw new Error("tick0 must be less than or equal to tick1");
    }
    if (tick1-tick0<=tickSpacing) {
        return BigInt(TickMath.getSqrtRatioAtTick(tick0).toString(10))
    }
    const tick = Math.floor((tick0 + tick1) / 2/tickSpacing)*tickSpacing;
    const priceSqrt = BigInt(TickMath.getSqrtRatioAtTick(tick).toString(10));
    if (tick === tick1 || tick === tick0) {
        return priceSqrt
    }
    return targetSqrt < priceSqrt?
        proximalPriceSqrt(targetSqrt, tick0, tick, tickSpacing):
        proximalPriceSqrt(targetSqrt, tick, tick1, tickSpacing);
}
