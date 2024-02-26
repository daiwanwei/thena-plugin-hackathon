'use client'

import {
    useReadAlgebraFactoryPoolByPair,
    useReadAlgebraPoolSafelyGetStateOfAmm,
    useReadAlgebraPoolToken0, useReadLimitOrderPluginIsFilled,
    useReadPerpetualGetPosition,
} from "@/generated";
import useAddressData from "@/hooks/useAddressData";
import {formatPrice} from "@/utils/common";
import {PerpPosition} from "@/types";
import useCoinData from "@/hooks/useCoinData";
import {useCallback, useState} from "react";
import { Decimal } from 'decimal.js';
import {useWatchBlockNumber} from "wagmi";
export interface PerpPositionData {
    collateralDecimals: number
    indexTokenDecimals: number
    perpPosition: PerpPosition
}


export default function usePerpPositionData(collateral:`0x${string}`,indexToken:`0x${string}`,user:`0x${string}`):PerpPositionData{
    const [blockNumber,setBlockNumber]=useState(BigInt(0))
    useWatchBlockNumber({
        onBlockNumber:(blockNumber)=>{
            setBlockNumber(blockNumber)
        }
    })
    const {
        perpetual,
        limitOrderPlugin
    }=useAddressData()
    console.log("perpetual",perpetual)
    console.log('args:',[user,collateral,indexToken,true])
    const perpData=useReadPerpetualGetPosition(
        {address:perpetual,args:[user,collateral,indexToken,true],blockNumber:blockNumber}
    ).data
    const epoch=perpData?.epoch || BigInt(0)
    const {
        coinDecimals:collateralDecimals
    }=useCoinData(collateral,user)
    const {
        coinDecimals:indexTokenDecimals
    }=useCoinData(indexToken,user)
    console.log("perpData",perpData)
    const isFilled=useReadLimitOrderPluginIsFilled({address:limitOrderPlugin,args:[epoch], blockNumber:blockNumber}).data || false
    const isOpening=perpData?.epoch!==BigInt(0)
    return {
        collateralDecimals,
        indexTokenDecimals,
        perpPosition:{
            user,
            collateral,
            indexToken,
            isLong:true,
            size:perpData?.size || BigInt(0),
            collateralAmount:perpData?.collateralAmount || BigInt(0),
            debt:perpData?.debt || BigInt(0),
            liquidity:perpData?.liquidity || BigInt(0),
            epoch:perpData?.epoch || BigInt(0),
            realisedPnl:perpData?.realisedPnl || BigInt(0),
            entryPrice:perpData?.entryPrice || BigInt(0),
            takeProfitPrice:perpData?.takeProfitPrice || BigInt(0),
            isFilled,
            isOpening
        }
    }
}

