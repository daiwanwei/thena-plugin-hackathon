import {Button, notification} from "antd";
import {
    useReadErc20Allowance,
    useWriteErc20Approve, useWriteErc20Mint, useWritePerpetualDecreasePosition,
    useWritePerpetualIncreasePosition, useWritePerpetualKillPosition,
    useWriteVaultDeposit,
    useWriteVaultWithdraw
} from "@/generated";
import {useAccount, useConnect, useWatchBlockNumber} from "wagmi";
import { injected } from 'wagmi/connectors'
import {ReactNode, useCallback, useEffect, useState} from "react";
import useUser from "@/hooks/useUser";
import useAddressData from "@/hooks/useAddressData";
import {formatPrice, proximalPriceSqrt} from "@/utils/common";
import usePerpPositionData from "@/hooks/usePerpPositionData";
import usePerpData from "@/hooks/usePerpData";


export interface OpenPositionButtonProps {
    collateral: `0x${string}`
    indexToken: `0x${string}`
    isLong: boolean
    pay: bigint
    indexAmount: bigint
    tpPrice: bigint
}
export function OpenPositionButton({collateral,indexToken,isLong,pay,indexAmount,tpPrice}: OpenPositionButtonProps) {
    const [blockNumber,setBlockNumber]=useState(BigInt(0))
    useWatchBlockNumber({
        onBlockNumber:(blockNumber)=>{
            setBlockNumber(blockNumber)
        }
    })
    const user=useUser()
    const {perpetual,wbnb}=useAddressData()
    const {priceSqrt}=usePerpData(collateral,indexToken,user)
    const allowance=useReadErc20Allowance({address:collateral,args:[user,perpetual],blockNumber:blockNumber}).data || BigInt(0)
    const [needToApprove,setNeedToApprove]=useState(false)
    const {writeContract,error}=useWritePerpetualIncreasePosition()
    const [api, contextHolder] = notification.useNotification();
    console.log(`collateral: ${collateral}`)
    console.log(`indexAmount: ${indexAmount}`)
    console.log(`pay: ${pay}`)
    console.log(`allowance: ${allowance}`)
    console.log(`tpPrice: ${tpPrice}`)
    console.log(`proximal price: ${formatPrice(proximalPriceSqrt(tpPrice))}`)
    console.log(`tp price: ${formatPrice(tpPrice)}`)
    const isLongWBNB= collateral.toLowerCase()===wbnb.toLowerCase()
    const isValidPrice=isLongWBNB?priceSqrt<tpPrice:priceSqrt>tpPrice

    const onAction=()=>{
        if (!isValidPrice) {
            api.error({
                message: 'Invalid Price',
                description:
                    'The take profit price is not valid',
            });
            return
        }
        console.log(`open position: ${collateral} ${indexToken} ${isLong} ${pay} ${indexAmount} ${tpPrice}`)
        writeContract({address:perpetual,args:[{
            collateralToken:collateral,
            indexToken:indexToken,
            isLong:true,
            collateralAmount:pay,
            indexAmount:indexAmount,
            takeProfitPrice:proximalPriceSqrt(tpPrice)
            }]})
    }
    useEffect(() => {
        console.log(allowance,pay)
        if(allowance<pay){
            setNeedToApprove(true)
        }else{
            setNeedToApprove(false)
        }
    }, [allowance,pay]);

    useEffect(() => {
        if(error){
            api.error({
                message: 'Open Position Failed',
                description:
                    error.message,
            });
        }
    }, [api,error]);

    if (needToApprove) {
        return (
            <ApproveButton token={collateral} spender={perpetual} amount={pay}/>
        );
    }
    return (
        <>
            {contextHolder}
            <ConnectButton onClick={onAction}>
                Open Position
            </ConnectButton>
        </>
    );

}

export interface ClosePositionButtonProps {
    collateral: `0x${string}`
    indexToken: `0x${string}`
    isLong: boolean
}

export function ClosePositionButton({collateral,indexToken,isLong}: ClosePositionButtonProps) {
    const [api, contextHolder] = notification.useNotification();
    const user=useUser()
    const positionData=usePerpPositionData(
        collateral,indexToken,user
    )
    const {perpetual}=useAddressData()
    const isFilled=positionData.perpPosition.isFilled
    const {writeContract:kill,error:killErr}=useWritePerpetualKillPosition()
    const {writeContract: claim,error:claimErr}=useWritePerpetualDecreasePosition()
    const onAction=useCallback(()=>{
        const params={
            collateralToken:collateral,
            indexToken:indexToken,
            isLong:isLong
        }
        if (isFilled) {
            claim({address:perpetual,args:[params]})
        } else {
            kill({address:perpetual,args:[params]})
        }
    },[isFilled,perpetual,collateral,indexToken,isLong,kill,claim])
    useEffect(() => {
        if(killErr){
            api.error({
                message: 'Close Position Failed',
                description:
                    killErr.message,
            });
        }
        if (claimErr) {
            api.error({
                message: 'Claim Failed',
                description:
                    claimErr.message,
            });
        }
    }, [claimErr,killErr,api]);
    return (
        <>
            {contextHolder}
            <ConnectButton onClick={onAction}>
                {isFilled ? "Claim" : "Close"}
            </ConnectButton>
        </>
    );
}

export interface MintButtonProps {
    user: `0x${string}`
    token: `0x${string}`
    amount: bigint
}

export function MintButton({user,token,amount}: MintButtonProps) {
    const {writeContract,error}=useWriteErc20Mint()
    const onAction=()=>{
        writeContract({address:token,args:[user,amount]})
    }
    return (
        <ConnectButton onClick={onAction}>
            Mint
        </ConnectButton>
    );
}

export interface DepositButtonProps {
    token: `0x${string}`
    receiver: `0x${string}`
    amount: bigint
}
export function DepositButton({token,receiver,amount}: DepositButtonProps) {
    const [api, contextHolder] = notification.useNotification();
    const [blockNumber,setBlockNumber]=useState(BigInt(0))
    useWatchBlockNumber({
        onBlockNumber:(blockNumber)=>{
            setBlockNumber(blockNumber)
        }
    })
    const user=useUser()
    const [needToApprove,setNeedToApprove]=useState(false)
    const allowance=useReadErc20Allowance({address:token,args:[user,receiver],blockNumber:blockNumber}).data || BigInt(0)
    const {writeContract,error}=useWriteVaultDeposit()
    console.log(`receiver: ${receiver}`)
    const onAction=()=>{
        console.log(`receiver: ${receiver} ${amount} ${user}`)
        writeContract({address:receiver,args:[amount,user]})
    }
    useEffect(() => {
        console.log(allowance,amount)
        if(allowance<amount){
            setNeedToApprove(true)
        }else{
            setNeedToApprove(false)
        }
    }, [allowance,amount]);
    useEffect(() => {
        if(error){
            api.error({
                message: 'Deposit Failed',
                description:
                    error.message,
            });
        }
    }, [error,api]);
  if (needToApprove) {
    return (
      <ApproveButton token={token} spender={receiver} amount={amount}/>
    );
  }
    return (
        <ConnectButton onClick={onAction}>
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
    const [api, contextHolder] = notification.useNotification();
    const {writeContract,error}=useWriteErc20Approve()
    const onAction= ()=>{
        writeContract({address:token,args:[spender,amount]})
    }

    useEffect(() => {
        if(error){
            api.error({
                message: 'Approve Failed',
                description:
                    error.message,
            });
        }
    }, [error,api]);
  return (
      <>
          {contextHolder}
          <ConnectButton onClick={onAction}>
              Approve
          </ConnectButton>
      </>
  );
}

export interface WithdrawButtonProps {
    vault: `0x${string}`
    receiver: `0x${string}`
    amount: bigint
}

export function WithdrawButton({vault,receiver,amount}: WithdrawButtonProps) {
    const {writeContract}=useWriteVaultWithdraw()
    const onAction= ()=>{
        writeContract({address:vault,args:[amount,receiver,receiver]})
    }
    return (
        <ConnectButton onClick={onAction}>
            Withdraw
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
