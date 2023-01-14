import { ethers } from "hardhat";

async function main() {
  const Bridge = await ethers.getContractFactory("WrappingBridge");
  const bridge = await Bridge.deploy();

  await bridge.deployed();

  console.log(`Bridge deployed to: ${bridge.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
