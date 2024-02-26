'use client'
import {Button, Card, InputNumber, Tabs} from "antd";
import {TokenSelect} from "@/components/TokenSelect";
import {useCallback, useEffect, useState} from "react";
import useVaultData from "@/hooks/useVaultData";
import {formatAmount, formatBalances} from "@/utils/common";
import {DepositButton, SwapButton, WithdrawButton} from "@/components/Button";
import useAddressData from "@/hooks/useAddressData";
import useUser from "@/hooks/useUser";
import useCoinData from "@/hooks/useCoinData";
import usePriceData from "@/hooks/usePriceData";
const onChange = (key: string) => {
    console.log(key);
};


export function SwapCard() {
    const [tokenIn, setTokenIn] = useState<string>('usdc');
    const [tokenOut,setTokenOut] = useState<string>('wbnb');
    const [amountIn,setAmountIn] = useState<string>('0');
    const [amountOut,setAmountOut] = useState<string>('0');
    const onTokenInSelect = (token: string) => {
        setTokenIn(token);
    }
    const onTokenOutSelect = (token: string) => {
        setTokenOut(token);
    }

    const onAmountInChange = (value: string | null) => {
        if (value===null) {
            return;
        }
        setAmountIn(value);
    }

    const user=useUser()
    const {wbnb,usdc,}=useAddressData()
    const tokenInAddress=tokenIn==='usdc'? usdc:wbnb;
    const tokenOutAddress=tokenOut==='usdc'? usdc:wbnb;
    const zeroToOne=tokenIn==='wbnb'
    const price=usePriceData(tokenInAddress,tokenOutAddress,zeroToOne);
    const {coinBalances,coinDecimals}=useCoinData(tokenInAddress,user)
    return (
        <Card bordered={false} style={{ width: 600 }}>
            <div className="flex flex-col gap-2">
                <div className="flex flex-row justify-between gap-10">
                    <p>your Balances</p>
                    <p>{formatBalances(coinBalances,coinDecimals)}</p>
                </div>
                <div className="flex flex-row justify-between gap-10">
                    <TokenSelect defaultToken={"usdc"} onSelect={onTokenInSelect} />
                    <InputNumber<string>
                        style={{ width: 200 }}
                        defaultValue="0"
                        min="0"
                        max="100000000000000000000000"
                        step="0.01"
                        onChange={onAmountInChange}
                        stringMode
                    />
                </div>
                <div className="flex flex-row justify-between items-center gap-10">
                    <TokenSelect defaultToken={"wbnb"} onSelect={onTokenOutSelect} />
                    <p>{(parseFloat(amountIn)*price).toFixed(2)}</p>
                </div>
                <div className="flex flex-row justify-between gap-10">
                    <SwapButton
                        tokenIn={tokenInAddress}
                        tokenOut={tokenOutAddress}
                        amount={BigInt(formatAmount(amountIn,coinDecimals))}
                        receiver={user}
                    />
                </div>
            </div>
        </Card>
    );
}
