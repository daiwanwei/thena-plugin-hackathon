import { ethers } from "hardhat";

async function main() {

  const poolFactory = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const wNativeToken= "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  const poolDeployer= "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2";

  const BasePluginV1Factory = await ethers.getContractFactory("BasePluginV1Factory");
  const dsFactory = await BasePluginV1Factory.deploy(poolFactory);

  await dsFactory.waitForDeployment()

  console.log("PluginFactory to:", dsFactory.target);

  const CallbackValidation = await ethers.getContractFactory("CallbackValidation");
  const callbackValidation=await CallbackValidation.deploy();
  await callbackValidation.waitForDeployment()
  console.log("callbackValidation to:", callbackValidation.target);
  const LimitOrderPlugin = await ethers.getContractFactory("LimitOrderPlugin",{
    libraries: {
      CallbackValidation: callbackValidation.target
    }
  });

  const limitOrderPlugin = await LimitOrderPlugin.deploy(
      wNativeToken,
      poolDeployer,
      dsFactory.target,
      poolFactory
  );
    await limitOrderPlugin.waitForDeployment()
    console.log("LimitOrderPlugin to:", limitOrderPlugin.target);

  // const factory = await hre.ethers.getContractAt('IAlgebraFactory', deploysData.factory)
  //
  // await factory.setDefaultPluginFactory(dsFactory.target)
  // console.log('Updated plugin factory address in factory')

  // deploysData.BasePluginV1Factory = dsFactory.target;
  // fs.writeFileSync(deployDataPath, JSON.stringify(deploysData), 'utf-8');
  // console.log(
  //   `Lock with ${ethers.formatEther(
  //     lockedAmount
  //   )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
  // );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
