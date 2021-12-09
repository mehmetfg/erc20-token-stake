const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("Staking", function () {

    let token, Token, owner, addr1, addr2;
    let staking, Staking;
    it("Deyploy", async function () {
        Token = await ethers.getContractFactory("Token");
        token = await Token.deploy();
        [owner, addr1, addr2, _] = await ethers.getSigners();
        await token.deployed();
        Staking = await ethers.getContractFactory("Staking");
        staking = await Staking.deploy(token.address, owner.address);
        staking.deployed();
        //expect(await token.totalSupply()).to.equal(100000000000);

        /* const setGreetingTx = await greeter.setName("Hola, mundo!");

         // wait until the transaction is mined
         await setGreetingTx.wait();

         expect(await greeter.getName()).to.equal("Hola, mundo!");*/
    });

    it("Sözleşmeye Token Approve İşlemi yap", async () => {
        await token.approve(staking.address, 10000);
        let allowance =Number(await token.allowance(owner.address, staking.address, ))
        expect(allowance).to.equal(10000);
        //console.log("gönderilen",10000000)
    })
    it("Müşteriye 1. Stake İşlemi Yap", async () => {

        await staking.stake(addr1.address, 1000, 180, 1000);


        await staking.stake(addr1.address, 500, 180, 1000);
        // console.log("stake edilen",1000, "hakadiş", 1100)
    })
    it("Müşterinin Stake edilmiş bakiyesini sorgula", async () => {
        let balanceOf = Number(await staking.balanceOf(addr1.address));
        expect(balanceOf).to.equal(1650);
    })
    it("1. Stake Owner Hesabın Bakiyesini sorgula", async () => {
        let balanceOfOwner =  await token.balanceOf(owner.address);
        expect(Number(balanceOfOwner)).to.equal(8350)
    })
    it("Müşteriye 2. Stake İşlemi Yap", async () => {
        await staking.stake(addr2.address, 500, 360, 1000);
    })
    it("2. Stake Owner Hesabın Bakiyesini sorgula", async () => {
       let balanceOfOwner =  await token.balanceOf(owner.address);
       expect(Number(balanceOfOwner)).to.equal(7800)
    })
    it("Müşterinin Stake edilmiş bakiyesini sorgula", async () => {
        let balanceOf = Number(await staking.balanceOf(addr2.address));
        expect(balanceOf).to.equal(550);
    })

    it("Stake 1 deki  zamanı gelmiş parayı Müşteri Çektir", async () => {
        await network.provider.send("evm_increaseTime", [3600 * 24 * 180])
        await network.provider.send("evm_mine")
       // console.log(Number(await staking.balanceOf(owner.address)));
        await staking.connect(addr1).withdraw(0);
      // console.log(Number(await staking.balanceOf(owner.address)));
        //let balanceOf =
        await staking.connect(addr1).withdraw(0);
        expect(Number(await token.balanceOf(addr1.address))).to.equal(1650);

    })
    it("Stake 1 deki  Müşterinin Stake Sözleşmesindeki bakiyesini sogrgula ", async () => {

        expect(Number(await staking.balanceOf(addr1.address))).to.equal(0);

    })
    it("Stake 2 deki zamanı gelmiş parayı Müşteri Çektir", async () => {
        await network.provider.send("evm_increaseTime", [3600 * 24 * 360])
        await network.provider.send("evm_mine")
        //console.log(Number(await staking.balanceOf(owner.address)));
        await staking.connect(addr2).withdraw(0);
       // console.log(Number(await staking.balanceOf(owner.address)));
        expect(Number(await token.balanceOf(addr2.address))).to.equal(550);

    })
    it("Stake 2 deki  Müşterinin Stake Sözleşmesindeki bakiyesini sogrgula ", async () => {

        expect(Number(await staking.balanceOf(addr2.address))).to.equal(0);

    })
    // it("Stake Sözleşmesine Müşteri Approve İşlemi yapıyor", async () => {
    //     await token.approve(staking.address, 1000);
    //
    //     expect(Number(await token.allowance(owner.address, staking.address))).to.equal(1000);
    //
    // })
/*    it("Approve edilmiş rakamı, sözleşmeye çekiyoruz", async () => {
      //  console.log(Number(await staking.balanceOf(owner.address)));
        await staking.transferFrom(owner.address, 720, 10);
        expect(Number(await staking.balanceOf(owner.address))).to.equal(1750);
    })*/
/*    it("Hakedilmiş miktarı müşteriye gönderiyoz", async () => {
        await network.provider.send("evm_increaseTime", [3600 * 24 * 720])
        await network.provider.send("evm_mine")
        await staking.withdraw(owner.address, 0);
        expect(Number(await token.balanceOf(owner.address))).to.equal(99990001750);

    })*/
});
