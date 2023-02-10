const { network, ethers } = require("hardhat");
const { developmentChains, networkConfig } = require("../helper-hardhat-config");
const { storeImages, storeTokenUriMetadata } = require("../utils/uploadToPinata");
const { verify } = require("../utils/verify");

const imagesLocation = "./images/randomNft";

const metadataTemplate = {
  name: "",
  description: "",
  imageUrl: "",
  attributes: [
    {
      trait_type: "Cuteness",
      value: 0,
    },
  ],
};

let dogTokenUris = [
  "ipfs://QmVET9m2G9NXgjNjkwbKAuuac5RqHn29vkizZKrmdaWtfc",
  "ipfs://QmXzSwGdz5FgduCEFuEpehhNHj5YA2cxS1EUnsMm8NhM8q",
  "ipfs://QmZu7R4nhPMAv3uf9q1MuZgz3uSSHi1MhwoeMQ4jhcv4cN",
];

const FUND_AMOUNT = ethers.utils.parseUnits("10"); // 10 LINK

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;

  // get the IPFS hashes of our nft images
  // 1. with our own IPFS node
  // 2. with Pinata - IPFS pinning service, pinata is simply an IPFS node run by someone else
  // 3. with NFT.storage (most decentralized way) - uses filecoin network on the backend to pin our data (filecoin is a blockchain for pinning IPFS data)

  // get the IPFS hashes of our images
  if (process.env.UPLOAD_TO_PINATA === "true") {
    dogTokenUris = await handleTokenUris();
  }

  let vrfCoordinatorAddress, subscriptionId;

  if (developmentChains.includes(network.name)) {
    // it is because when deploying on a local network, there is no live VRF Coordinator contracts like on testnets or mainnet
    // we have to manually deploy a mock contract and subscribe to it
    const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock");
    vrfCoordinatorAddress = vrfCoordinatorV2Mock.address;

    // create our subscription to the VRF Coordinator
    const txResponse = await vrfCoordinatorV2Mock.createSubscription();
    const txReceipt = await txResponse.wait(1);

    // createSubscription() in vrfCoordinatorV2Mock contract emitted a SubscriptionCreated event which lets us get the parameter passed with it
    subscriptionId = txReceipt.events[0].args.subId;
    await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, FUND_AMOUNT);
  } else {
    vrfCoordinatorAddress = networkConfig[network.config.chainId].vrfCoordinatorV2;
    subscriptionId = networkConfig[network.config.chainId].subscriptionId;
  }

  const gaslane = networkConfig[network.config.chainId].gasLane;
  const callbackGasLimit = networkConfig[network.config.chainId].callbackGasLimit;
  const mintFee = networkConfig[network.config.chainId].mintFee;

  // args have to follow contract's constructor method signature
  const args = [
    vrfCoordinatorAddress,
    subscriptionId,
    gaslane,
    callbackGasLimit,
    dogTokenUris,
    mintFee,
  ];
  const randomNft = await deploy("RandomIpfsNft", {
    from: deployer,
    args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    console.log("Verifying contract...");
    await verify(randomNft.address, args);
  }

  log("-------------------------------------------------------");
};

const handleTokenUris = async () => {
  tokenUris = [];

  // store the image in ipfs
  const { responses: imageUploadResponses, imageFiles } = await storeImages(imagesLocation);

  for (imageUploadResponseIndex in imageUploadResponses) {
    let tokenUriMetadata = { ...metadataTemplate };
    tokenUriMetadata.name = imageFiles[imageUploadResponseIndex].replace(".png", "");
    tokenUriMetadata.description = `Hi, I am an adorable ${tokenUriMetadata.name} puppy :3`;
    tokenUriMetadata.imageUrl = `ipfs://${imageUploadResponses[imageUploadResponseIndex].IpfsHash}`;

    console.log(`Uploading metadata for ${tokenUriMetadata.name} NFT...`);

    // store the JSON metadata to pinata / IPFS
    const metadataUploadResponse = await storeTokenUriMetadata(tokenUriMetadata);

    tokenUris.push(`ipfs://${metadataUploadResponse.IpfsHash}`);
  }

  console.log(`Token URIs uploaded to Pinata: ${tokenUris}`);

  return tokenUris;
};

module.exports.tags = ["all", "randomnft", "main"];
