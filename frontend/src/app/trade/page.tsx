'use client';
import Image from "next/image";
import {ConnectButton} from "@rainbow-me/rainbowkit";
import {Button, DatePicker, Space} from "antd";
import React from "react";
import Head from "next/head";
import {TokenSelect} from "@/components/TokenSelect";
import {VaultActionCard} from "@/components/VaultActionCard";
import useVaultData from "@/hooks/useVaultData";
import {DepositButton} from "@/components/Button";
import useAddressData from "@/hooks/useAddressData";
import {useAccount} from "wagmi";
import usePerpData from "@/hooks/usePerpData";
import {PerpActionCard} from "@/components/PerpActionCard";

export default function Page() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
        <PerpActionCard/>
    </main>
  );
}
