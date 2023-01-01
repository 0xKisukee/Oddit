// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.

async function main() {
    const [owner, signer1] = await ethers.getSigners();

    // Deploy Token
    const TemplateToken = await ethers.getContractFactory("TemplateToken");
    const templateToken = await TemplateToken.deploy();

    // Deploy Master
    const TemplateMaster = await ethers.getContractFactory("TemplateMaster");
    const templateMaster = await TemplateMaster.deploy();

    // Set Master address
    await templateToken.setMaster(templateMaster.address);

    // Set Token address
    await templateMaster.setToken(templateToken.address);

    // Set fees to 2.5%
    await templateMaster.setFees(2500);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
