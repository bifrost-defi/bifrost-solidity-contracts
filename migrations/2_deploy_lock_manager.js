const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const LockManager = artifacts.require("LockManager");

module.exports = async function (deployer) {
  const instance = await deployProxy(LockManager, { deployer });
  console.log("Deployed", instance.address);
};
