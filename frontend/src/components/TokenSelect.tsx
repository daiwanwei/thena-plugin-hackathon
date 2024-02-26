import React from "react";
import {Select} from "antd";
import Icon from "@ant-design/icons";



interface TokenSelectProps {
    defaultToken: string;
    onSelect: (token: string) => void;
}

const items=[
    {
        value: 'usdc',
        label: <div>
            <Icon
                component={() => <img src='/usdc.svg' width={15} height={15} />}/>
            {'  USDC'}
        </div>,
    },
    {
        value: 'wbnb',
        label: <div>
            <Icon
                component={() => <img src='/bnb.svg' width={15} height={15} />}/>
            {'  BNB'}
        </div>,
    }
];


export function TokenSelect({defaultToken="usdc",onSelect}: TokenSelectProps){
    return(
        <Select
            defaultValue={defaultToken}
            style={{ width: 200 }}
            onChange={onSelect}
            options={items}
        />
    );
}
