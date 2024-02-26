'use client'

import {useChainId} from "wagmi";

export interface AddressData {
    perpetual: `0x${string}`
    vaultFactory: `0x${string}`
    poolFactory: `0x${string}`
    limitOrderPlugin: `0x${string}`
    usdc: `0x${string}`
    wbnb: `0x${string}`

}


export default function useAddressData():AddressData{
    const chainId = useChainId()
    if (chainId === 97){
        return {
            perpetual: "0x78719659B56B87DD04E6aD82903d51de1afbf13D",
            vaultFactory: "0xfFAE599ba8305739A3F0aD3dacED0f5F624D3A23",
            poolFactory: "0xD4829bcA3cFecf576B64f4Cb3150E2196BF2b30B",
            limitOrderPlugin: "0xf141a14984a02D5C250EF0Fe93dB146b57e897CC",
            usdc: "0xcd55D6E8F74DD5863CC33B347f8C500C59FC2dF5",
            wbnb: "0x8c2dcB633e8715379eE64FC2fd8726B883f298F1"
        }
    }
    return {
        perpetual: "0x78719659B56B87DD04E6aD82903d51de1afbf13D",
        vaultFactory: "0xfFAE599ba8305739A3F0aD3dacED0f5F624D3A23",
        poolFactory: "0xD4829bcA3cFecf576B64f4Cb3150E2196BF2b30B",
        limitOrderPlugin: "0xf141a14984a02D5C250EF0Fe93dB146b57e897CC",
        usdc: "0xcd55D6E8F74DD5863CC33B347f8C500C59FC2dF5",
        wbnb: "0x8c2dcB633e8715379eE64FC2fd8726B883f298F1"
    }
}
