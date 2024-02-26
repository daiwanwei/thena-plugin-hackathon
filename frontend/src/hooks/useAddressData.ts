'use client'

export interface AddressData {
    perpetual: `0x${string}`
    vaultFactory: `0x${string}`
    poolFactory: `0x${string}`
    limitOrderPlugin: `0x${string}`
    usdc: `0x${string}`
    wbnb: `0x${string}`

}


export default function useAddressData():AddressData{
    return {
        perpetual: "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e",
        vaultFactory: "0x610178dA211FEF7D417bC0e6FeD39F05609AD788",
        poolFactory: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
        limitOrderPlugin: "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707",
        usdc: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
        wbnb: "0x5FbDB2315678afecb367f032d93F642f64180aa3"
    }
}
