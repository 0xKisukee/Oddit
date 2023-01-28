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

  // Create odditMatch (FRA - MAR)
  const OdditMatch_1 = await ethers.getContractFactory("OdditMatch");
  const odditMatch_1 = await OdditMatch_1.deploy(odditMaster.address, "FRA - MAR", 0);
  await odditMatch_1.deployed();
  console.log("Deploy odditMatch 1 : " + odditMatch_1.address);

  // Synchronize artifacts
  await hre.ethernal.push({
    name: 'DaiToken',
    address: dai.address
  });
  await hre.ethernal.push({
    name: 'OdditMaster',
    address: odditMaster.address
  });
  await hre.ethernal.push({
    name: 'OdditMatch',
    address: odditMatch_1.address
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
