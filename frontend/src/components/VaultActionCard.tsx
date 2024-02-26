'use client'
import {Button, Card, InputNumber, Tabs} from "antd";
import {TokenSelect} from "@/components/TokenSelect";
import {useCallback, useEffect, useState} from "react";
import useVaultData from "@/hooks/useVaultData";
import {formatAmount, formatBalances} from "@/utils/common";
import {DepositButton, WithdrawButton} from "@/components/Button";
import useAddressData from "@/hooks/useAddressData";
import useUser from "@/hooks/useUser";
const onChange = (key: string) => {
    console.log(key);
};


export function VaultActionCard() {
    const [token, setToken] = useState<string>('usdc');
    const onTokenSelect = (token: string) => {
        setToken(token);
    }
    const items = [
        {
            key: '1',
            label: 'Deposit',
            children: <ActionItem action={"deposit"} token={token} onTokenSelect={onTokenSelect} />,
        },
        {
            key: '2',
            label: 'Withdraw',
            children: <ActionItem action={"withdraw"} token={token} onTokenSelect={onTokenSelect} />,
        }
    ]
    return (
        <Card bordered={false} style={{ width: 600 }}>
            <Tabs defaultActiveKey="1" items={items} onChange={onChange} />
        </Card>
    );
}

interface ActionItemProps {
    action: 'deposit' | 'withdraw';
    token: string;
    onTokenSelect: (token: string) => void;
}

export function ActionItem({action,token,onTokenSelect}: ActionItemProps) {
    const [inputBalances, setInputBalances] = useState<string>('0');
    const {wbnb,usdc}=useAddressData()
    const asset=token==='usdc'?usdc:wbnb
    const collateral=token==='usdc'?wbnb:usdc
    const user= useUser()
    const {
        vault,
        totalAssets,
        assetDecimals,
        assetBalances,
        pTokenDecimals,
        pTokenBalances,
    }= useVaultData(asset,collateral,user)

    const onAmountChange = useCallback((value: string | null) => {
        if (value) {
            setInputBalances(value);
        }
    },[]);

    return (
        <div className="flex flex-col gap-2">
            <div className="flex flex-row justify-between gap-10">
                <p>total Liquidity</p>
                <p>{formatBalances(totalAssets,assetDecimals)}</p>
            </div>
            {action === 'deposit' ? (
                <div className="flex flex-row justify-between gap-10">
                    <p>your Balances</p>
                    <p>{formatBalances(assetBalances,assetDecimals)}</p>
                </div>
            ) : (
                <div className="flex flex-row justify-between gap-10">
                    <p>supplied</p>
                    <p>{formatBalances(pTokenBalances,pTokenDecimals)}</p>
                </div>
            )}
            <div className="flex flex-row justify-between gap-10">
                <TokenSelect onSelect={onTokenSelect} />
                <InputNumber<string>
                    style={{ width: 200 }}
                    defaultValue="0"
                    min="0"
                    max="100000000000000000000000"
                    step="0.01"
                    onChange={onAmountChange}
                    stringMode
                />
            </div>
            <div className="flex flex-row justify-between gap-10">
                {action === 'deposit' ? (
                    <DepositButton token={asset} receiver={vault} amount={BigInt(formatAmount(inputBalances,assetDecimals))} />
                ) : (
                   <WithdrawButton vault={vault} receiver={user} amount={BigInt(formatAmount(inputBalances,assetDecimals))}/>
                )}
            </div>
        </div>
    );
}
