require("dotenv").config();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const LockManager = artifacts.require("LockManager");

module.exports = async function (deployer) {
  const instance = await deployProxy(LockManager, [process.env.USDC_CONTRACT], {
    deployer,
  });
  console.log("Deployed", instance.address);
};
