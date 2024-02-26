'use client'

import {
    useReadAlgebraFactoryPoolByPair, useReadAlgebraPoolSafelyGetStateOfAmm, useReadAlgebraPoolToken0,
} from "@/generated";
import useAddressData from "@/hooks/useAddressData";
import {formatPrice} from "@/utils/common";
import {PerpPosition} from "@/types";
import useCoinData from "@/hooks/useCoinData";
import {useCallback, useState} from "react";
import { Decimal } from 'decimal.js';
import {useWatchBlockNumber} from "wagmi";
export interface PerpData {
    // totalAssets: string
    // totalDebt: string
    // totalCollateral: string
    // pool data
    price: string
    priceSqrt: bigint
    // user data
    collateralBalances: string
    collateralDecimals: number
    // pTokenBalances: string
    // pTokenDecimals: number

    getIndexTokenAmount: (collateralAmount:bigint,leverage:bigint) => bigint

}


export default function usePerpData(collateral:`0x${string}`,indexToken:`0x${string}`,user:`0x${string}`):PerpData{
    const [blockNumber,setBlockNumber]=useState(BigInt(0))
    useWatchBlockNumber({
        onBlockNumber:(blockNumber)=>{
            setBlockNumber(blockNumber)
        }
    })
    const {
        perpetual,
        poolFactory
    }=useAddressData()
    const pool=(useReadAlgebraFactoryPoolByPair({address:poolFactory,args:[collateral,indexToken]}).data?.toString()||'0x0000000000000000000000000000000000000000') as `0x${string}`
    const poolState=useReadAlgebraPoolSafelyGetStateOfAmm({address:pool,blockNumber:blockNumber}).data
    const token0=(useReadAlgebraPoolToken0({address:pool}).data?.toString() ||'0x0000000000000000000000000000000000000000') as `0x${string}`
    const collateralIsToken0=token0.toLowerCase()===collateral.toLowerCase()
    const priceSqrt=poolState? poolState[0]:BigInt(0)
    let price='0'
    if (priceSqrt!==BigInt(0)){
        price=formatPrice(priceSqrt,collateralIsToken0,5)
    }
    const {
        coinBalances:collateralBalances,
        coinDecimals:collateralDecimals
    }=useCoinData(collateral,user)

    const getIndexTokenAmount=useCallback((collateralAmount:bigint,leverage:bigint):bigint=>{
        if (price==='0'){
            return BigInt(0)
        }
        const positionSize=collateralAmount*leverage
        const indexTokenAmount=collateralIsToken0?
            new Decimal(positionSize.toString()).dividedBy(price).toFixed(0):
            new Decimal(positionSize.toString()).mul(price).toFixed(0)
        return BigInt(indexTokenAmount.toString())
    },[collateralIsToken0,price])
    // const totalAssets=useReadVaultTotalAssets({address:vault,chainId:1337})
    // const totalDebt=useReadVaultTotalDebt({address:vault})
    // const totalCollateral=useReadVaultTotalCollateral({address:vault})
    // const {
    //     coinDecimals:assetDecimals,
    //     coinBalances:assetBalances
    // }=useCoinData(asset,user)
    // const {
    //     coinDecimals:pTokenDecimals,
    //     coinBalances:pTokenBalances
    // }=useCoinData(vault,user)
    return {
        price,priceSqrt,collateralBalances,collateralDecimals,getIndexTokenAmount
    }
}

