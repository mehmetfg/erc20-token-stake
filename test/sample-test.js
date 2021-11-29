const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("Staking", function () {

    let token, Token, owner, addr1, addr2;
    let stake, Stake;
    it("Deyploy", async function () {
        Token = await ethers.getContractFactory("Token");
        token = await Token.deploy();
        [owner, addr1, addr2, _] = await ethers.getSigners();
        await token.deployed();
        Stake = await ethers.getContractFactory("Stake");
        stake = await Stake.deploy(token.address);
        stake.deployed();
        //expect(await token.totalSupply()).to.equal(100000000000);

        /* const setGreetingTx = await greeter.setName("Hola, mundo!");

         // wait until the transaction is mined
         await setGreetingTx.wait();

         expect(await greeter.getName()).to.equal("Hola, mundo!");*/
    });

    it("Sözleşmeye Token Gönder", async () => {
        await token.transfer(stake.address, 10000000);
        expect(await stake.contractERC20Balance()).to.equal(10000000);
        //console.log("gönderilen",10000000)
    })
    it("Müşteriye 1. Stake İşlemi Yap", async () => {
        await stake.deposite(owner.address, 1000, 180, 10);
        // console.log("stake edilen",1000, "hakadiş", 1100)
    })
    it("Müşteriye 2. Stake İşlemi Yap", async () => {
        await stake.deposite(owner.address, 500, 360, 10);
    })


    it("Stake 1 deki  zamanı gelmiş parayı Müşteri Çektir", async () => {
        await network.provider.send("evm_increaseTime", [3600 * 24 * 180])
        await network.provider.send("evm_mine")
        await stake.withdraw(owner.address, 0);

        expect(await token.balanceOf(owner.address)).to.equal(99990001100);


    })
    it("Stake 2 deki zamanı gelmiş parayı Müşteri Çektir", async () => {
        await network.provider.send("evm_increaseTime", [3600 * 24 * 180])
        await network.provider.send("evm_mine")
        await stake.withdraw(owner.address, 0);

        expect(await token.balanceOf(owner.address)).to.equal(99990001650);

    })
    it("Stake Sözleşmesine Müşteri Approve İşlemi yapıyor", async () => {
        await token.approve(stake.address, 1000);

        expect(await token.allowance(owner.address, stake.address)).to.equal(1000);

    })
    it("Approve edilmiş rakamı, sözleşmeye çekiyoruz", async () => {
        await stake.transferFrom(owner.address, 720, 10);
        expect(await stake.balanceOf(owner.address)).to.equal(1100);
    })
    it("Hakedilmiş miktarı müşteriye gönderiyoz", async () => {
        await network.provider.send("evm_increaseTime", [3600 * 24 * 720])
        await network.provider.send("evm_mine")
        await stake.withdraw(owner.address, 0);
        expect(await token.balanceOf(owner.address)).to.equal(99990001750);

    })
});
