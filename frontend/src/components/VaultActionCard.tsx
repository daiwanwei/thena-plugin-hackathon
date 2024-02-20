import {Button, Card, InputNumber, Tabs} from "antd";
import {TokenSelect} from "@/components/TokenSelect";
import {useState} from "react";
import useVaultData from "@/hooks/useVaultData";
import {formatBalances} from "@/utils/common";
import {DepositButton} from "@/components/Button";
import useAddressData from "@/hooks/useAddressData";
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
    const [amount, setAmount] = useState<string>('0');
    const {wbnb,usdc}=useAddressData()
    const asset=token==='usdc'?usdc:wbnb
    const collateral=token==='usdc'?wbnb:usdc
    const user= "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    const {
        vault,
        totalAssets,
        assetDecimals,
        assetBalances,
        pTokenDecimals,
        pTokenBalances,
    }= useVaultData(asset,collateral,user)
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
                    <p>your Balances</p>
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
                    step="0.000001"
                    onChange={(value:string | null) => {
                        console.log(value);
                    }}
                    stringMode
                />
            </div>
            <div className="flex flex-row justify-between gap-10">
                <DepositButton token={asset} receiver={vault} amount={BigInt(1000000000000000000)} />
            </div>
        </div>
    );
}
