const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("Token Staking ", function () {

    let token, Token, owner, addr1, addr2;
    let staking, Staking;


    describe("Token Deploy",  function () {

        it("Deploy", async () => {
            Token = await ethers.getContractFactory("Token");
            token = await Token.deploy();
            [owner, addr1, addr2, _] = await ethers.getSigners();

        })
        it("Token Owner Doğrulama", async () => {
            expect(await token.owner()).to.equal(owner.address);

        })
        it("Token Total Supply Doğrulama", async () => {
            const ownerBalance = await  token.balanceOf(owner.address);
            expect(Number(await token.totalSupply())).to.equal(Number(ownerBalance));

        })


        /* const setGreetingTx = await greeter.setName("Hola, mundo!");

         // wait until the transaction is mined
         await setGreetingTx.wait();

         expect(await greeter.getName()).to.equal("Hola, mundo!");*/
    });

    describe("Staking Deploy",  function () {
        it("Deploy", async () => {
            Staking = await ethers.getContractFactory("Staking");
            staking = await Staking.deploy(token.address, owner.address);

        })
        it("Staking Owner Doğrulama", async () => {

            expect(await staking.owner()).to.equal(owner.address);

        })
        it("Staking Contract Token Bakiyesi Doğrulama", async () => {

            expect(Number(await staking.contractBalanceOf())).to.equal(0);
        })
    })


    describe("Token Transactions", function (){

        it("Sözleşmeye Token Approve İşlemi yap", async () => {
            await token.approve(staking.address, 10000)
            let allowance =Number(await token.allowance(owner.address, staking.address, ))
            expect(allowance).to.equal(10000);
            //console.log("gönderilen",10000000)
        })
    })
    describe("Stake Transactions", function (){


        it("Müşteriye 1. Stake İşlemi Yap", async () => {
            await staking.stake(addr1.address, 100, 180, 1000);




            let balanceOf = Number(await staking.balanceOf(addr1.address))
            expect(balanceOf).to.equal(110)


            // console.log("stake edilen",1000, "hakadiş", 1100)
        })
        it("Müşteriye 2. Stake İşlemi Yap", async () => {

            await staking.stake(addr1.address, 500, 360, 1000);
            balanceOf = Number(await staking.balanceOf(addr1.address))
            expect(balanceOf).to.equal(660)
            // console.log("stake edilen",1000, "hakadiş", 1100)
        })

        it("Staking Contract Token Bakiyesi Doğrulama", async () => {

            expect(Number(await staking.contractBalanceOf())).to.equal(660);
        })
        it("Stake 1 deki  zamanı gelmiş parayı Müşteri Çektir", async () => {
            await network.provider.send("evm_increaseTime", [3600 * 24 * 180])
            await network.provider.send("evm_mine")
            // console.log(Number(await staking.balanceOf(owner.address)));
            await staking.connect(addr1).withdraw(0);
            expect(Number(await staking.balanceOf(addr1.address))).to.equal(550);
            expect(Number(await token.balanceOf(addr1.address))).to.equal(110);


        })
        it("Stake 1 deki  zamanı gelmiş parayı Müşteri Çektir", async () => {
            await network.provider.send("evm_increaseTime", [3600 * 24 * 180])
            await network.provider.send("evm_mine")


            await staking.connect(addr1).withdraw(0);
            expect(Number(await staking.balanceOf(addr1.address))).to.equal(0);
            expect(Number(await token.balanceOf(addr1.address))).to.equal(660);

        })
    })



});
