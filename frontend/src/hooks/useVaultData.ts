'use client'

import {createContext, useContext, useState} from "react";
import {
    useReadVaultBalanceOf,
    useReadVaultDecimals, useReadVaultFactory, useReadVaultFactoryVaults,
    useReadVaultTotalAssets,
    useReadVaultTotalCollateral,
    useReadVaultTotalDebt
} from "@/generated";
import useCoinData from "@/hooks/useCoinData";
import useAddressData from "@/hooks/useAddressData";
import {useWatchBlockNumber} from "wagmi";

export interface VaultData {
    vault: `0x${string}`

    totalAssets: string
    totalDebt: string
    totalCollateral: string

    assetBalances: string
    assetDecimals: number

    pTokenBalances: string
    pTokenDecimals: number
}


export default function useVaultData(asset:`0x${string}`,collateral:`0x${string}`,user:`0x${string}`):VaultData{
    const [blockNumber,setBlockNumber]=useState(BigInt(0))
    useWatchBlockNumber({
        onBlockNumber:(blockNumber)=>{
            setBlockNumber(blockNumber)
        }
    })
    const {vaultFactory}=useAddressData()
    const vault =(useReadVaultFactoryVaults({address:vaultFactory,args:[asset,collateral]}).data?.toString() || "0x0000000000000000000000000000000000000000") as `0x${string}`
    const totalAssets=useReadVaultTotalAssets({address:vault,blockNumber:blockNumber})
    const totalDebt=useReadVaultTotalDebt({address:vault,blockNumber:blockNumber})
    const totalCollateral=useReadVaultTotalCollateral({address:vault,blockNumber:blockNumber})
    const {
        coinDecimals:assetDecimals,
        coinBalances:assetBalances
    }=useCoinData(asset,user)
    const {
        coinDecimals:pTokenDecimals,
        coinBalances:pTokenBalances
    }=useCoinData(vault,user)
    return {
        vault,
        totalAssets:totalAssets.data?.toString()||'0',
        totalDebt:totalDebt.data?.toString()||'0',
        totalCollateral:totalCollateral.data?.toString()||'0',
        assetBalances:assetBalances,
        assetDecimals:assetDecimals,
        pTokenBalances:pTokenBalances,
        pTokenDecimals:pTokenDecimals
    }
}

