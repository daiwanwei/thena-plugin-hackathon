import {Button, Card, InputNumber, Tabs} from "antd";
import {TokenSelect} from "@/components/TokenSelect";
import {useEffect, useState} from "react";
import useVaultData from "@/hooks/useVaultData";
import {encodePriceSqrt, formatAmount, formatBalances} from "@/utils/common";
import {DepositButton, OpenPositionButton} from "@/components/Button";
import usePerpData from "@/hooks/usePerpData";
import useAddressData from "@/hooks/useAddressData";
import useUser from "@/hooks/useUser";
import BigNumber from "bignumber.js";
const onChange = (key: string) => {
    console.log(key);
};

const items = [
    {
        key: '1',
        label: 'Short',
        children: <ActionItem collateral={"usdc"} />,
    },
    {
        key: '2',
        label: 'Long',
        children: <ActionItem collateral={"wbnb"} />,
    }
]

export function PerpActionCard() {
    return (
        <Card bordered={false} style={{ width: 600 }}>
            <Tabs defaultActiveKey="1" items={items} onChange={onChange} />
        </Card>
    );
}

interface ActionItemProps {
    collateral: 'usdc' | 'wbnb';
}

export function ActionItem({collateral}: ActionItemProps) {
    const {wbnb,usdc}=useAddressData()
    const collateralToken=collateral==='usdc'?usdc:wbnb
    const indexToken=collateral==='usdc'?wbnb:usdc
    const user=useUser()
    const {price,price0,getIndexTokenAmount,collateralBalances,collateralDecimals}=usePerpData(collateralToken,indexToken,user)
    const [leverage,setLeverage] = useState<number>(1);
    const [pay,setPay] = useState<number>(0);
    const [takeProfit,setTakeProfit] = useState<number>(0);
    const [positionSize,setPositionSize] = useState<number>(0);

    const onLeverageChange = (value: string | null) => {
        if (value) {
            setLeverage(Number(value));
        }
    }

    const onPayChange = (value: string | null) => {
        if (value) {
            setPay(Number(value));
        }
    }

    const onTakeProfitChange = (value: string | null) => {
        if (value) {
            setTakeProfit(Number(value));
        }
    }

    useEffect(() => {
        setPositionSize(pay*leverage);
    }, [pay,leverage]);

    return (
        <div className="flex flex-col gap-2">
            <div className="flex flex-row justify-between gap-10">
                <p>Collateral</p>
                <p>{collateral}</p>
            </div>
            <div className="flex flex-row justify-between gap-10">
                <p>Token Price</p>
                <p>{price0}</p>
            </div>
            <div className="flex flex-row justify-between gap-10">
                <p>your Balances</p>
                <p>{formatBalances(collateralBalances,collateralDecimals)}</p>
            </div>
            <div className="flex flex-row justify-between gap-10 items-center">
                <p>Leverage </p>
                <InputNumber<string>
                    style={{ width: 200 }}
                    defaultValue="1"
                    min="1"
                    max="10"
                    step="1"
                    onChange={onLeverageChange}
                    stringMode
                />
            </div>
            <div className="flex flex-row justify-between gap-10 items-center">
                <p>Pay </p>
                <InputNumber<string>
                    style={{ width: 200 }}
                    defaultValue="0"
                    min="0"
                    max="1000000000000"
                    step="0.01"
                    onChange={onPayChange}
                    stringMode
                />
            </div>
            <div className="flex flex-row justify-between gap-10 items-center">
                <p>Take Profit </p>
                <InputNumber<string>
                    style={{ width: 200 }}
                    defaultValue="0"
                    min="0"
                    max="1000000"
                    step="0.01"
                    onChange={onTakeProfitChange}
                    stringMode
                />
            </div>
            <div className="flex flex-row justify-between gap-10 items-center">
                <p>Position Size </p>
                <p>{positionSize}</p>
            </div>
            <OpenPositionButton
                collateral={collateralToken}
                indexToken={indexToken}
                isLong={true}
                pay={BigInt(formatAmount(pay.toString(),collateralDecimals))}
                indexAmount={BigInt(getIndexTokenAmount(BigInt(formatAmount(pay.toString(),collateralDecimals)),BigInt(leverage)))}
                tpPrice={encodePriceSqrt(BigNumber(takeProfit))}
            />
        </div>
    );
}
