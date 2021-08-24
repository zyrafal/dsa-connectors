const { expect } = require("chai");
const hre = require("hardhat");
const { web3, deployments, waffle, ethers } = hre;
const { provider, deployContract } = waffle;

const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js");
const buildDSAv2 = require("../../scripts/buildDSAv2");
const encodeSpells = require("../../scripts/encodeSpells.js");
const encodeFlashcastData = require("../../scripts/encodeFlashcastData.js");
const getMasterSigner = require("../../scripts/getMasterSigner");

const addresses = require("../../scripts/constant/addresses");
const abis = require("../../scripts/constant/abis");
const constants = require("../../scripts/constant/constant");
const tokens = require("../../scripts/constant/tokens");

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
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!masterSigner.address).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });
  });
});
