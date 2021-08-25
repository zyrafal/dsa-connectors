const { expect } = require("chai");
const hre = require("hardhat");
const { waffle, ethers } = hre;
const { provider, parseEther, getContractAt } = waffle;

const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js");
const buildDSAv2 = require("../../scripts/buildDSAv2");
const getMasterSigner = require("../../scripts/getMasterSigner");

const addresses = require("../../scripts/constant/addresses");
const abis = require("../../scripts/constant/abis");

const connectV2UbiquityArtifacts = require("../../artifacts/contracts/mainnet/connectors/ubiquity/main.sol/ConnectV2Ubiquity.json");

describe("Ubiquity", function () {
  const connectorName = "UBIQUITY-TEST-A";

  let dsaWallet0;
  let masterSigner;
  let instaConnectorsV2;
  let connector;

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;
  before(async () => {
    masterSigner = await getMasterSigner(wallet3);
    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2
    );
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: connectV2UbiquityArtifacts,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
    console.log("Connector address", connector.address);
  });

  it("Should have contracts deployed.", async function () {
    expect(instaConnectorsV2.address).to.be.properAddress;
    expect(connector.address).to.be.properAddress;
    expect(masterSigner.address).to.be.properAddress;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(dsaWallet0.address).to.be.properAddress;
    });

    it("Should deposit ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10"),
      });
      expect(await provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );
    });
  });
});
