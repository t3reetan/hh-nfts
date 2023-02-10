const { network } = require("hardhat");
const pinataSDK = require("@pinata/sdk");
const path = require("path");
const fs = require("fs");

const pinataApiKey = process.env.PINATA_API_KEY;
const pinataApiSecret = process.env.PINATA_API_SECRET;

const pinata = pinataSDK(pinataApiKey, pinataApiSecret);

const storeImages = async (imagesFilePath) => {
  // get the absolute path of the images folder
  const fullImageFilesPath = path.resolve(imagesFilePath);

  // read files from the images folder (directory)
  const imageFiles = fs.readdirSync(fullImageFilesPath);

  let responses = [];

  console.log("Uploading images to Pinata...");

  for (const imageFile in imageFiles) {
    console.log(`Working on ${imageFile}`);

    const readableStreamForFile = fs.createReadStream(
      `${fullImageFilesPath}/${imageFiles[imageFile]}`
    );

    try {
      // this is how a response will look like after uploading an image to pinata:
      //{
      //     IpfsHash: This is the IPFS multi-hash provided back for your content,
      //     PinSize: This is how large (in bytes) the content you just pinned is,
      //     Timestamp: This is the timestamp for your content pinning (represented in ISO 8601 format)
      // }
      const response = await pinata.pinFileToIPFS(readableStreamForFile);
      responses.push(response);
    } catch (err) {
      console.log(`Error while uploading image to Pinata: ${err}`);
    }
  }

  return { responses, imageFiles };
};

const storeTokenUriMetadata = async (tokenUriMetadata) => {
  try {
    const response = pinata.pinJSONToIPFS(tokenUriMetadata);
    return response;
  } catch (err) {
    console.log(`Error while uploading metadata to Pinata: ${err}`);
  }
  return null;
};

module.exports = { storeImages, storeTokenUriMetadata };
