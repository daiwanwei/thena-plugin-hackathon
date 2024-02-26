import useUser from "@/hooks/useUser";
import useAddressData from "@/hooks/useAddressData";
import usePerpPositionData from "@/hooks/usePerpPositionData";
import {Button, List, Skeleton} from "antd";
import {formatBalances, formatPrice} from "@/utils/common";
import {useWritePerpetualKillPosition} from "@/generated";
import {ClosePositionButton} from "@/components/Button";


export default function UserPerpPositionList() {
    const user=useUser()
    const {wbnb,usdc,perpetual}=useAddressData();
    const longWbnb=usePerpPositionData(wbnb, usdc, user)
    const shortWbnb=usePerpPositionData(usdc, wbnb, user)
    console.log(`size: ${longWbnb.perpPosition.size}`)
    const list=[
        {
            longOrShort:"Long WBNB",
            margin:formatBalances(longWbnb.perpPosition.collateralAmount.toString(),longWbnb.collateralDecimals,4),
            positionSize:formatBalances(longWbnb.perpPosition.size.toString(),longWbnb.collateralDecimals,4),
            takeProfitPrice:formatPrice(longWbnb.perpPosition.takeProfitPrice,true,4),
            entryPrice:formatPrice(longWbnb.perpPosition.entryPrice,true,4),
            action:<ClosePositionButton collateral={wbnb} indexToken={usdc} isLong={true} />,
            isOpening:longWbnb.perpPosition.isOpening
        },
        {
            longOrShort:"Short WBNB",
            margin:formatBalances(shortWbnb.perpPosition.collateralAmount.toString(),shortWbnb.collateralDecimals,4),
            positionSize:formatBalances(shortWbnb.perpPosition.size.toString(),shortWbnb.collateralDecimals,4),
            takeProfitPrice:formatPrice(shortWbnb.perpPosition.takeProfitPrice,true,4),
            entryPrice: formatPrice(shortWbnb.perpPosition.entryPrice,true,4),
            action:<ClosePositionButton collateral={usdc} indexToken={wbnb} isLong={true} />,
            isOpening:shortWbnb.perpPosition.isOpening
        }
    ]
    return (
        <List
            className="w-[600px]"
            itemLayout="horizontal"
            dataSource={list}
            renderItem={(item) => (
                <List.Item
                    actions={[item.action]}
                >
                    <List.Item.Meta
                        title={<h1>{item.longOrShort}</h1>}
                    />
                    <div className='flex flex-row gap-4'>
                        <div>
                            <p>Margin: {item.margin}</p>
                            <p>Position Size: {item.positionSize}</p>
                        </div>
                        <div >
                            <p>Entry Price: {item.entryPrice}</p>
                            <p>Take Profit Price: {item.takeProfitPrice}</p>
                        </div>
                    </div>
                </List.Item>
            )}
        />
    )
}

interface DataType{
    longOrShort:string;
    margin:string;
    positionSize:string;
    entryPrice:string;
    takeProfitPrice:string;
    action:JSX.Element;
}
