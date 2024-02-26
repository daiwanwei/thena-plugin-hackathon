'use client'

import {createContext, useContext, useState} from "react";
import {
    useReadErc20BalanceOf,
    useReadErc20Decimals,
    useReadErc20Name, useReadErc20TotalSupply,
    useReadVaultBalanceOf,
    useReadVaultDecimals,
    useReadVaultTotalAssets,
    useReadVaultTotalCollateral,
    useReadVaultTotalDebt
} from "@/generated";
import {useWatchBlockNumber} from "wagmi";

export interface CoinData {
    coinName: string
    coinSymbol: string
    coinDecimals: number
    coinTotalSupply: string
    coinBalances: string
}


export default function useCoinData(coin:`0x${string}`,user:`0x${string}`):CoinData{
    const [blockNumber,setBlockNumber]=useState(BigInt(0))
    useWatchBlockNumber({
        onBlockNumber:(blockNumber)=>{
            setBlockNumber(blockNumber)
        }
    })
    const coinName=useReadErc20Name({address:coin})
    const coinSymbol=useReadErc20Name({address:coin})
    const coinDecimals=useReadErc20Decimals({address:coin})
    const coinTotalSupply=useReadErc20TotalSupply({address:coin,blockNumber:blockNumber})
    const coinBalance=useReadErc20BalanceOf({address:coin,args:[user],blockNumber:blockNumber})

    return {
        coinName:coinName.data?.toString()||'',
        coinSymbol:coinSymbol.data?.toString()||'',
        coinDecimals:parseInt(coinDecimals.data?.toString()||"0"),
        coinTotalSupply:coinTotalSupply.data?.toString()||'0',
        coinBalances:coinBalance.data?.toString()||'0'
    }
}

