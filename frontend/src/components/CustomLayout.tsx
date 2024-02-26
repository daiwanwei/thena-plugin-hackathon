'use client';
import React from "react";
import { Breadcrumb, Layout, Menu, theme } from 'antd';
import {ConnectButton} from "@rainbow-me/rainbowkit";
import Link from "next/link";
const { Header, Content, Footer } = Layout;

const items=[
    {
        key: '1',
        label: <Link href={'/'}>Home</Link>,
    },
    {
        key: '2',
        label: <Link href={'/trade'}>Trade</Link>,
    },
    {
        key: '3',
        label: <Link href={'/earn'}>Earn</Link>,
    },
    {
        key: '4',
        label: <Link href={'/swap'}>Swap</Link>,
    },
    {
        key: '5',
        label: <Link href={'/faucet'}>Faucet</Link>,
    },
]

export function CustomLayout({ children }: { children: React.ReactNode }) {
  return (
      <Layout>
          <Header style={{ display: 'flex', alignItems: 'center' }}>
              <div className="demo-logo" />
              <Menu
                  theme="dark"
                  mode="horizontal"
                  defaultSelectedKeys={['2']}
                  items={items}
                  style={{ flex: 1, minWidth: 0 }}
              />
              <ConnectButton/>
          </Header>
          <Content style={{ padding: '0 48px' }}>
              {children}
          </Content>
      </Layout>
  );
}
