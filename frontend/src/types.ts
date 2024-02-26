

export interface PerpPosition {
    user: `0x${string}`
    collateral: `0x${string}`
    indexToken: `0x${string}`
    isLong: boolean
    size: bigint
    collateralAmount: bigint
    debt: bigint
    liquidity: bigint
    epoch: bigint
    entryPrice: bigint
    takeProfitPrice: bigint
    realisedPnl: bigint
    isFilled: boolean
    isOpening: boolean
}

