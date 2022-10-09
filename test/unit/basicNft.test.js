const { assert, expect } = require("chai");
const { ethers, getNamedAccounts, deployments, network } = require("hardhat");
const { developmentChains, networkConfig } = require("../../helper-hardhat-config");

// only run these tests on development chains
!developmentChains.includes(network.name)
  ? describe.skip
  : describe("BasicNFT", () => {
      let basicNFT, deployer;

      beforeEach(async () => {
        deployer = (await getNamedAccounts()).deployer;

        await deployments.fixture(["basicnft"]);

        basicNFT = await ethers.getContract("BasicNFT", deployer);
      });

      // test 1
      describe("constructor", () => {
        it("initializes the NFT correctly", async () => {
          const name = await basicNFT.name();
          const symbol = await basicNFT.symbol();
          const tokenCounter = await basicNFT.getTokenCounter();

          assert.equal(name, "Dogy");
          assert.equal(symbol, "DOG");
          assert.equal(tokenCounter.toString(), "0");
        });
      });

      describe("mint nft", () => {
        it("allows users to mint an NFT, and updates accordingly", async () => {
          // mint an NFT
          const txRes = await basicNFT.mintNft();
          await txRes.wait(1);

          // check token counter
          const tokenCounter = await basicNFT.getTokenCounter();
          assert.equal(tokenCounter.toString(), "1");

          // check token URI
          const tokenURI = await basicNFT.tokenURI(0);
          assert.equal(tokenURI, await basicNFT.TOKEN_URI());
        });
      });
    });
