const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { Contract } = require("ethers");
const ethernal = require('hardhat-ethernal');

async function main() {
  // Deploy dai
  const DAI = await ethers.getContractFactory("DaiToken");
  const dai = await DAI.deploy();
  await dai.deployed();
  console.log("Deploy dai : " + dai.address);

  // Deploy odditMaster
  const OdditMaster = await ethers.getContractFactory("OdditMaster");
  const odditMaster = await OdditMaster.deploy();
  await odditMaster.deployed();
  console.log("Deploy odditMaster : " + odditMaster.address);

  // Set the first currency (DAI)
  await odditMaster.addCurrency(0, "DAI", dai.address);

  // Set fees
  await odditMaster.setFees(2500);

  // Create odditMatch
  const OdditMatch = await ethers.getContractFactory("OdditMatch");
  const odditMatch = await OdditMatch.deploy();
  await odditMatch.deployed();
  console.log("Deploy odditMatch : " + odditMatch.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
