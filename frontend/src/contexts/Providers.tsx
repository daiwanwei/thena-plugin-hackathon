'use client';

import * as React from 'react';
import {
    RainbowKitProvider,
    getDefaultWallets,
    getDefaultConfig,
} from '@rainbow-me/rainbowkit';
import {
    argentWallet,
    trustWallet,
    ledgerWallet,
} from '@rainbow-me/rainbowkit/wallets';
import {
    mainnet,
    localhost, opBNBTestnet, bscTestnet
} from 'wagmi/chains';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider } from 'wagmi';
import {AntdRegistry} from "@ant-design/nextjs-registry";

const { wallets } = getDefaultWallets();

const config = getDefaultConfig({
    appName: 'RainbowKit demo',
    projectId: 'YOUR_PROJECT_ID',
    wallets: [
        ...wallets,
        {
            groupName: 'Other',
            wallets: [argentWallet, trustWallet, ledgerWallet],
        },
    ],
    chains: [
        bscTestnet,
        opBNBTestnet,
        localhost
    ],
    ssr: true,
});

const queryClient = new QueryClient();

export function Providers({ children }: { children: React.ReactNode }) {
    return (
        <WagmiProvider config={config}>
            <QueryClientProvider client={queryClient}>
                <RainbowKitProvider>
                    <AntdRegistry>
                        {children}
                    </AntdRegistry>
                </RainbowKitProvider>
            </QueryClientProvider>
        </WagmiProvider>
    );
}
