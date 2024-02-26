'use client'
import {Button, Card, InputNumber, Tabs} from "antd";
import {TokenSelect} from "@/components/TokenSelect";
import {useCallback, useEffect, useState} from "react";
import useVaultData from "@/hooks/useVaultData";
import {formatAmount, formatBalances} from "@/utils/common";
import {DepositButton, MintButton, WithdrawButton} from "@/components/Button";
import useAddressData from "@/hooks/useAddressData";
import useUser from "@/hooks/useUser";
import {useWriteErc20Mint} from "@/generated";
import useCoinData from "@/hooks/useCoinData";


export function FaucetCard() {
    const [token, setToken] = useState<string>('usdc');
    const onTokenSelect = (token: string | null) => {
        if (token) {
            setToken(token);
        }
    }

    const [inputBalances, setInputBalances] = useState<string>('0');
    const {wbnb,usdc}=useAddressData()
    const coin= token==='usdc'?usdc:wbnb
    const user= useUser()

    const {coinTotalSupply,coinDecimals,coinBalances}=useCoinData(coin,user)

    const onAmountChange = useCallback((value: string | null) => {
        if (value) {
            setInputBalances(value);
        }
    },[]);


    return (
        <Card bordered={false} style={{ width: 600 }}>
            <div className="flex flex-col gap-2">
                <div className="flex flex-row justify-between gap-10">
                    <p>total Supply</p>
                    <p>{formatBalances(coinTotalSupply,coinDecimals)}</p>
                </div>
                <div className="flex flex-row justify-between gap-10">
                    <p>your Balances</p>
                    <p>{formatBalances(coinBalances,coinDecimals)}</p>
                </div>
                <div className="flex flex-row justify-between gap-10">
                    <TokenSelect defaultToken={"usdc"} onSelect={onTokenSelect} />
                    <InputNumber<string>
                        style={{ width: 200 }}
                        defaultValue="0"
                        min="0"
                        max="100"
                        step="0.01"
                        onChange={onAmountChange}
                        stringMode
                    />
                </div>
                <div className="flex flex-row justify-between gap-10">
                    <MintButton token={coin} user={user} amount={BigInt(formatAmount(inputBalances,coinDecimals))} />
                </div>
            </div>
        </Card>
    );
}
