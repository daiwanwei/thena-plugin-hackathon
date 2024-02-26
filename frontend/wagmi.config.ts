import { defineConfig } from '@wagmi/cli'
import VAULT_ABI from './src/abis/Vault.json'
import ERC20_ABI from './src/abis/ERC20.json'
import PERPETUAL_ABI from './src/abis/Perpetual.json'
import SWAP_ROUTER_ABI from './src/abis/SwapRouter.json'
import VAULT_FACTORY_ABI from './src/abis/VaultFactory.json'
import ALGEBRA_FACTORY_ABI from './src/abis/AlgebraFactory.json'
import ALGEBRA_POOL_ABI from './src/abis/AlgebraPool.json'
import LIMIT_ORDER_PLUGIN_ABI from './src/abis/LimitOrderPlugin.json'
import {react} from "@wagmi/cli/plugins";
export default defineConfig({
  out: 'src/generated.ts',
  contracts: [
    {
      name: 'vault',
      //@ts-ignore
      abi: VAULT_ABI,
    },
    {
      name: 'erc20',
      //@ts-ignore
      abi: ERC20_ABI,
    },
    {
      name: 'swapRouter',
      //@ts-ignore
      abi: SWAP_ROUTER_ABI,
    },
    {
      name: 'vaultFactory',
      //@ts-ignore
      abi: VAULT_FACTORY_ABI,
    },
    {
      name: 'perpetual',
      //@ts-ignore
      abi: PERPETUAL_ABI,
    },
    {
      name: 'algebraFactory',
      //@ts-ignore
      abi: ALGEBRA_FACTORY_ABI,
    },
    {
      name: 'algebraPool',
      //@ts-ignore
      abi: ALGEBRA_POOL_ABI,
    },
    {
      name: 'limitOrderPlugin',
      //@ts-ignore
      abi: LIMIT_ORDER_PLUGIN_ABI,
    },
  ],
  plugins: [
    react()
  ],
})
