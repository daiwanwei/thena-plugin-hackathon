import { defineConfig } from '@wagmi/cli'
import VAULT_ABI from './src/abis/Vault.json'
import ERC20_ABI from './src/abis/ERC20.json'
import PERPETUAL_ABI from './src/abis/Perpetual.json'
import SWAP_ROUTER_ABI from './src/abis/SwapRouter.json'
import VAULT_FACTORY_ABI from './src/abis/VaultFactory.json'
import ALGEBRA_FACTORY_ABI from './src/abis/AlgebraFactory.json'
import ALGEBRA_POOL_ABI from './src/abis/AlgebraPool.json'
import {react} from "@wagmi/cli/plugins";
export default defineConfig({
  out: 'src/generated.ts',
  contracts: [
    {
      name: 'vault',
      abi: VAULT_ABI,
    },
    {
      name: 'erc20',
      abi: ERC20_ABI,
    },
    {
      name: 'swapRouter',
      abi: SWAP_ROUTER_ABI,
    },
    {
      name: 'vaultFactory',
      abi: VAULT_FACTORY_ABI,
    },
    {
        name: 'perpetual',
        abi: PERPETUAL_ABI,
    },
    {
        name: 'algebraFactory',
        abi: ALGEBRA_FACTORY_ABI,
    },
    {
        name: 'algebraPool',
        abi: ALGEBRA_POOL_ABI,
    },
  ],
  plugins: [
    react()
  ],
})
