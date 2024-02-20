'use client'

export interface AddressData {
    perpetual: `0x${string}`
    vaultFactory: `0x${string}`
    poolFactory: `0x${string}`
    usdc: `0x${string}`
    wbnb: `0x${string}`

}


export default function useAddressData():AddressData{
    return {
        perpetual: "0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82",
        vaultFactory: "0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0",
        poolFactory: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
        usdc: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
        wbnb: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
    }
}
