# Teahouse Marge

## Project Overview
Teahouse Marge is a revolutionary decentralized margin trading protocol, tailored to operate within THENA's Automated Market Maker (AMM) in the BNB Chain ecosystem. The protocol harnesses the unique features of THENA Plugins to introduce novel strategies and mechanisms in the DeFi sector, aiming to significantly enhance liquidity and trading volume.

## Roles in the Contracts

The contracts define three main roles:

1. **Trader**: This role is responsible for executing trades on the platform.

2. **Liquidity Provider**: This role is responsible for providing liquidity to the platform. They can add or remove liquidity as needed.

3. **Liquidator**: This role is responsible for liquidating positions when necessary.


## Scenario

The contracts are designed to be used in the following scenario:

### Opening a Position

```mermaid
sequenceDiagram
    participant Trader
    participant PerpetualContract
    Trader->>PerpetualContract: 1. Approve Collateral Token
    Trader->>PerpetualContract: 2. Open Position And Deposit Collateral
```

### Closing a Position

```mermaid
sequenceDiagram
    participant Trader
    participant PerpetualContract
    Trader->>PerpetualContract: 1. Close Position
    PerpetualContract-->>Trader: 2. Refund Collateral Token And Payout Profit
```

### Providing Liquidity

```mermaid
sequenceDiagram
    participant LiquidityProvider
    participant PerpetualVault
    LiquidityProvider->>PerpetualVault: 1. Approve Asset Token
    LiquidityProvider->>PerpetualVault: 2. Add Liquidity
```

### Removing Liquidity

```mermaid
sequenceDiagram
    participant LiquidityProvider
    participant PerpetualVault
    LiquidityProvider->>PerpetualVault: 1. Remove Liquidity
    PerpetualVault-->>LiquidityProvider: 2. Refund Asset Token And Payout Liquidity Reward
```

### Liquidating a Position

```mermaid
sequenceDiagram
    participant Liquidator
    participant PerpetualContract
    Liquidator->>PerpetualContract: 1. Liquidate Position
    PerpetualContract-->>Liquidator: 2. Payout Liquidation Reward
```
