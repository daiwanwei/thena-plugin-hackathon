import BigNumber from "bignumber.js";
import { Decimal } from 'decimal.js';
export function formatBalances(balances: string, decimals: number, fixed=2): string {
  return BigNumber(balances)
      .dividedBy(BigNumber(10 ** decimals))
      .toFixed(fixed);
}

export function formatPrice(priceSqrt: bigint,isToken0Price = true): string {
   const price0=new Decimal(priceSqrt.toString()).dividedBy(new Decimal(2).pow(96)).toPrecision(3);
   const price1=(new Decimal(1).dividedBy(price0)).toPrecision(3);
   return isToken0Price?price0:price1;
}

export function encodePriceSqrt(price:BigNumber): bigint {
    return BigInt(
        price.sqrt()
            .multipliedBy(new BigNumber(2).pow(96))
            .integerValue(3)
            .toString()
    );
}
