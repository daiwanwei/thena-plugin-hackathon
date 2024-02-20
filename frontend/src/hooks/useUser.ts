'use client'

import {createContext, useContext, useEffect, useState} from "react";
import {
    useReadVaultBalanceOf,
    useReadVaultDecimals,
    useReadVaultTotalAssets,
    useReadVaultTotalCollateral,
    useReadVaultTotalDebt
} from "@/generated";
import useCoinData from "@/hooks/useCoinData";
import {useAccount} from "wagmi";




export default function useUser():`0x${string}`{
    const [user,setUser]=useState<`0x${string}`>("0x0000000000000000000000000000000000000000")
    const {address}=useAccount()
    useEffect(()=>{
        if (address){
            setUser(address)
        }
    },[address])
    return user
}

