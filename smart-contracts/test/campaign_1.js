const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Campaign 1", function () {
    let owner, signer1, signer2, signer3, signer4, signer5, signer6, signer7, signer8, signer9, daiToken, odditMaster, odditMatchA;

    before("Deployments and initial setup", async function () {
        [owner, signer1, signer2, signer3, signer4, signer5, signer6, signer7, signer8, signer9] = await ethers.getSigners();

        DaiToken = await ethers.getContractFactory("DaiToken");
        daiToken = await DaiToken.deploy();

        OdditMaster = await ethers.getContractFactory("OdditMaster")
        odditMaster = await OdditMaster.deploy();

        // Set the first currency (DAI)
        await odditMaster.addCurrency(0, "DAI", daiToken.address);

        // Set fees
        await odditMaster.setFees(2500);
    });

    describe("Match creation, transfers and approvals", function () {
        it("Owner creates match A", async function () {
            currentTime = await time.latest()

            OdditMatch = await ethers.getContractFactory("OdditMatch")
            odditMatchA = await OdditMatch.deploy(odditMaster.address, "FRA - MAR", currentTime);

            await odditMaster.addMatch(odditMatchA.address);

            expect(
                await odditMatchA.matchExpiration()
            ).to.equal(
                currentTime + Number(await odditMatchA.expirationCooldown())
            );

            expect(
                await odditMatchA.master()
            ).to.equal(
                await odditMaster.address
            );

            expect(
                await odditMaster.isMatch(odditMatchA.address)
            ).to.equal(
                true
            );
        });

        it("Signers sets currency to DAI", async function () {
            await odditMaster.connect(signer1).setCurrency(daiToken.address);
            await odditMaster.connect(signer2).setCurrency(daiToken.address);
            await odditMaster.connect(signer3).setCurrency(daiToken.address);
            await odditMaster.connect(signer4).setCurrency(daiToken.address);
            await odditMaster.connect(signer5).setCurrency(daiToken.address);
            await odditMaster.connect(signer6).setCurrency(daiToken.address);
            await odditMaster.connect(signer7).setCurrency(daiToken.address);
            await odditMaster.connect(signer8).setCurrency(daiToken.address);
            await odditMaster.connect(signer9).setCurrency(daiToken.address);
        });

        it("Owner sends 1000 DAI to signers", async function () {
            await daiToken.transfer(signer1.address, 1000);
            await daiToken.transfer(signer2.address, 1000);
            await daiToken.transfer(signer3.address, 1000);
            await daiToken.transfer(signer4.address, 1000);
            await daiToken.transfer(signer5.address, 1000);
            await daiToken.transfer(signer6.address, 1000);
            await daiToken.transfer(signer7.address, 1000);
            await daiToken.transfer(signer8.address, 1000);
            await daiToken.transfer(signer9.address, 1000);
        });

        it("Signers approves 1000 DAI to odditMaster", async function () {
            await daiToken.connect(signer1).approve(odditMaster.address, 1000);
            await daiToken.connect(signer2).approve(odditMaster.address, 1000);
            await daiToken.connect(signer3).approve(odditMaster.address, 1000);
            await daiToken.connect(signer4).approve(odditMaster.address, 1000);
            await daiToken.connect(signer5).approve(odditMaster.address, 1000);
            await daiToken.connect(signer6).approve(odditMaster.address, 1000);
            await daiToken.connect(signer7).approve(odditMaster.address, 1000);
            await daiToken.connect(signer8).approve(odditMaster.address, 1000);
            await daiToken.connect(signer9).approve(odditMaster.address, 1000);
        });
    });

    describe("Some random test", function () {
        it("Creation of 8 orders", async function () {
            await odditMaster.connect(signer1).callOrder(odditMatchA.address, 1, 400, 100);
            await odditMaster.connect(signer2).callOrder(odditMatchA.address, 1, 420, 250);
            await odditMaster.connect(signer3).callOrder(odditMatchA.address, 1, 450, 200);
            await odditMaster.connect(signer4).callOrder(odditMatchA.address, 1, 500, 300);
            await odditMaster.connect(signer5).callOrder(odditMatchA.address, 2, 140, 150);
            await odditMaster.connect(signer6).callOrder(odditMatchA.address, 2, 150, 200);
            await odditMaster.connect(signer7).callOrder(odditMatchA.address, 2, 170, 100);
            await odditMaster.connect(signer8).callOrder(odditMatchA.address, 2, 200, 200);
        });

        it("Creation of 2 market orders", async function () {
            await odditMaster.connect(signer9).callOrder(odditMatchA.address, 1, 101, 150);
            await odditMaster.connect(signer9).callOrder(odditMatchA.address, 2, 101, 200);

            // Check orders
            expect(
                (await odditMatchA.ORDERS(4)).remainingAmount
            ).to.equal(
                0
            );

            expect(
                (await odditMatchA.ORDERS(5)).remainingAmount
            ).to.equal(
                20
            );

            // Check bets
            expect(
                (await odditMatchA.BETS(0)).amount
            ).to.equal(
                60
            );

            expect(
                (await odditMatchA.BETS(1)).amount
            ).to.equal(
                150
            );

            expect(
                (await odditMatchA.BETS(2)).amount
            ).to.equal(
                90
            );

            expect(
                (await odditMatchA.BETS(3)).amount
            ).to.equal(
                180
            );
        });

        it("Delete an order", async function () {
            await odditMatchA.connect(signer6).deleteOrder(5);

            expect(
                (await odditMatchA.ORDERS(5)).remainingAmount
            ).to.equal(
                0
            );
        });

        it("Create a huge order", async function () {
            await odditMaster.connect(signer9).callOrder(odditMatchA.address, 1, 101, 600);
        });

    });

    describe("Visual checks", function () {
        it("Check signer 9 orders", async function () {
            let list = await odditMaster.getOrders(signer9.address);
            let size = list.length;

            console.log("Signer9:");
            for (let i = 0; i < size; i++) {
                let id = Number(list[i].id);

                console.log("/////");
                console.log(
                    "Side: " + (await odditMatchA.ORDERS(id)).side
                );
                console.log(
                    "Odds: " + (await odditMatchA.ORDERS(id)).odds / 100
                );
                console.log(
                    "Amount: " + (await odditMatchA.ORDERS(id)).remainingAmount
                );
            }
        });

        it("Check signer 9 bets", async function () {
            let list = await odditMaster.getBets(signer9.address);
            let size = list.length;

            console.log("Signer9:");
            for (let i = 0; i < size; i++) {
                let id = Number(list[i].id);

                console.log("/////");
                console.log(
                    "Side: " + (await odditMatchA.BETS(id)).side
                );
                console.log(
                    "Odds: " + (await odditMatchA.BETS(id)).odds / 100
                );
                console.log(
                    "Amount: " + (await odditMatchA.BETS(id)).amount
                );
            }
        });
    });

    describe("Signer1 and Signer2 try to claim their bets", function () {

    });
});