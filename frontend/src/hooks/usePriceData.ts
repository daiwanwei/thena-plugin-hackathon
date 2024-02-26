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

export default function usePriceData(token0:`0x${string}`,token1:`0x${string}`,zeroToOne:boolean=true):number{
    const [blockNumber,setBlockNumber]=useState(BigInt(0))
    useWatchBlockNumber({
        onBlockNumber:(blockNumber)=>{
            setBlockNumber(blockNumber)
        }
    })
    const {
        poolFactory
    }=useAddressData()
    const pool=(useReadAlgebraFactoryPoolByPair({address:poolFactory,args:[token0,token1]}).data?.toString()||'0x0000000000000000000000000000000000000000') as `0x${string}`
    const poolState=useReadAlgebraPoolSafelyGetStateOfAmm({address:pool,blockNumber:blockNumber}).data
    const priceSqrt=poolState? poolState[0]:BigInt(0)
    let price=0
    if (priceSqrt!==BigInt(0)){
        price=parseFloat(formatPrice(priceSqrt,zeroToOne,5))
    }
    return price
}

