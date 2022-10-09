const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;

  // args have to follow contract's constructor method signature
  const args = [];
  const basicNft = await deploy("BasicNFT", {
    from: deployer,
    args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    console.log("Verifying contract...");
    await verify(basicNft.address, args);
  }

  log("-------------------------------------------------------");
};

module.exports.tags = ["all", "basicnft"];
