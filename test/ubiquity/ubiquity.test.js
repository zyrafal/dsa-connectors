const { expect } = require("chai");
const hre = require("hardhat");
const { waffle, ethers } = hre;
const { provider } = waffle;
const { BigNumber } = ethers;

const deployAndEnableConnector = require("../../scripts/deployAndEnableConnector.js");
const buildDSAv2 = require("../../scripts/buildDSAv2");
const encodeSpells = require("../../scripts/encodeSpells");
const addresses = require("../../scripts/constant/addresses");
const abis = require("../../scripts/constant/abis");
const impersonate = require("../../scripts/impersonate");
const { forkReset, sendEth } = require("./utils");

const connectV2UbiquityArtifacts = require("../../artifacts/contracts/mainnet/connectors/ubiquity/main.sol/ConnectV2Ubiquity.json");

describe.only("Ubiquity", function () {
  const ubiquityTest = "UBIQUITY-TEST-A";

  const blockFork = 13097100;
  const one = BigNumber.from(10).pow(18);
  const ethWhaleAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
  const crvWhaleAddress = "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd";
  const uAD3CRVf = "0x20955CB69Ae1515962177D164dfC9522feef567E";
  const uAD3CRVfABI = [
    "function balanceOf(address owner) view returns (uint256)",
    "function decimals() view returns (uint8)",
    "function symbol() view returns (string)",
    "function transfer(address to, uint amount) returns (boolean)",
    "event Transfer(address indexed from, address indexed to, uint amount)",
  ];

  let dsa;
  let uAD3CRVfContract;
  let instaIndex;
  let instaConnectorsV2;
  let connector;

  let crvWhale;

  let first = true;

  beforeEach(async () => {
    await forkReset(blockFork);

    [crvWhale] = await impersonate([crvWhaleAddress]);
    const [ethWhale] = await impersonate([ethWhaleAddress]);

    await sendEth(ethWhale, crvWhaleAddress, 100);
    dsa = await buildDSAv2(crvWhaleAddress);

    uAD3CRVfContract = new ethers.Contract(uAD3CRVf, uAD3CRVfABI);
    await uAD3CRVfContract
      .connect(crvWhale)
      .transfer(dsa.address, one.mul(100));
    await sendEth(ethWhale, dsa.address, 100);

    instaIndex = new ethers.Contract(
      addresses.core.instaIndex,
      abis.core.instaIndex,
      ethWhale
    );

    const masterAddress = await instaIndex.master();
    const [master] = await impersonate([masterAddress]);
    await sendEth(ethWhale, masterAddress, 100);

    instaConnectorsV2 = new ethers.Contract(
      addresses.core.connectorsV2,
      abis.core.connectorsV2
    );

    connector = await deployAndEnableConnector({
      connectorName: ubiquityTest,
      contractArtifact: connectV2UbiquityArtifacts,
      signer: master,
      connectors: instaConnectorsV2,
    });

    if (first) console.log(`Connector ${ubiquityTest} ${connector.address}`);
    first = false;
  });

  describe("DSA wallet setup", function () {
    it("Should have contracts deployed.", async function () {
      expect(dsa.address).to.be.properAddress;
      expect(uAD3CRVfContract.address).to.be.properAddress;
      expect(instaIndex.address).to.be.properAddress;
      expect(instaConnectorsV2.address).to.be.properAddress;
      expect(connector.address).to.be.properAddress;
    });

    it("Should deposit ETH into DSA wallet", async function () {
      expect(await provider.getBalance(dsa.address)).to.be.equal(
        ethers.utils.parseEther("100")
      );
    });

    it("Should deposit uAD3CRVf LPs into DSA wallet", async function () {
      expect(
        await uAD3CRVfContract.connect(crvWhale).balanceOf(dsa.address)
      ).to.be.equal(ethers.utils.parseEther("100"));
    });
  });

  describe("Main", function () {
    it("should deposit uAD3CRVf LPs in Ubiquity BondingV2", async function () {
      const lpAmout = one;
      const durationWeeks = 4;

      const spells = [
        {
          connector: ubiquityTest,
          method: "deposit",
          args: [lpAmout, durationWeeks, 0, 0],
        },
      ];

      const tx = await (
        await dsa
          .connect(crvWhale)
          .cast(...encodeSpells(spells), crvWhaleAddress)
      ).wait();
      console.log(tx);
    });
  });
});
