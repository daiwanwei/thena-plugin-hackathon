import {Button} from "antd";
import {useReadErc20Allowance, useWriteErc20Approve, useWriteVaultDeposit} from "@/generated";
import {useAccount, useConnect} from "wagmi";
import { injected } from 'wagmi/connectors'
import {ReactNode, useEffect, useState} from "react";


export interface DepositButtonProps {
    token: `0x${string}`
    receiver: `0x${string}`
    amount: bigint
}
export function DepositButton({token,receiver,amount}: DepositButtonProps) {
    const {address}=useAccount()
    const [user,setUser]=useState<`0x${string}`>("0x0000000000000000000000000000000000000000")
    const [needToApprove,setNeedToApprove]=useState(false)
    const allowance=useReadErc20Allowance({address:token,args:[user,receiver]}).data || BigInt(0)
    const {writeContract}=useWriteVaultDeposit()
    const onDeposit=()=>{
        writeContract({address:receiver,args:[amount,user]})
    }
    useEffect(() => {
        if(allowance<amount){
            setNeedToApprove(true)
        }else{
            setNeedToApprove(false)
        }
    }, [allowance,amount]);
    useEffect(() => {
        if(address){
            setUser(address)
        }
    }, [address]);
  if (needToApprove) {
    return (
      <ApproveButton token={token} spender={receiver} amount={amount}/>
    );
  }
    return (
        <ConnectButton onClick={onDeposit}>
        Deposit
        </ConnectButton>
    );
}

export interface ApproveButtonProps {
    token: `0x${string}`
    spender: `0x${string}`
    amount: bigint
}

export function ApproveButton({token,spender,amount}: ApproveButtonProps) {
    const {writeContract}=useWriteErc20Approve()
    const onApprove= ()=>{
        writeContract({address:token,args:[spender,amount]})
    }
  return (
    <ConnectButton onClick={onApprove}>
      Approve
    </ConnectButton>
  );
}

export interface ConnectButtonProps {
    onClick: ()=>void
    children: ReactNode
}

export function ConnectButton({onClick,children}: ConnectButtonProps) {
    const {isConnected}=useAccount()
    const {connect}=useConnect()
    const onClickForConnect=()=>{
        if(isConnected){
            onClick()
        }else{
            connect({connector: injected()})
        }
    }
  return (
    <Button className={"w-[100%]"} type="primary" size="large" onClick={onClickForConnect}>
      {isConnected? children:"Connect"}
    </Button>
  );
}
