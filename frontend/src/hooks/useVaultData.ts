'use client'

import {createContext, useContext} from "react";
import {
    useReadVaultBalanceOf,
    useReadVaultDecimals, useReadVaultFactory, useReadVaultFactoryVaults,
    useReadVaultTotalAssets,
    useReadVaultTotalCollateral,
    useReadVaultTotalDebt
} from "@/generated";
import useCoinData from "@/hooks/useCoinData";
import useAddressData from "@/hooks/useAddressData";

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
    const {vaultFactory}=useAddressData()
    const vault =(useReadVaultFactoryVaults({address:vaultFactory,args:[asset,collateral]}).data?.toString() || "0x0000000000000000000000000000000000000000") as `0x${string}`
    console.log(vault)
    const totalAssets=useReadVaultTotalAssets({address:vault})
    const totalDebt=useReadVaultTotalDebt({address:vault})
    const totalCollateral=useReadVaultTotalCollateral({address:vault})
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

