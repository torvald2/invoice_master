const {expect} = require("chai");
const {ethers} = require("hardhat");



describe("InvoiceMatching", () => {
    let acc1
    let acc2 
    let acc3
    let oracleContract
    let invoiceContract
    let invoiceContractAddress 
    let oracleContractAddress 
    beforeEach( async () => {
       [acc1,acc2,acc3]=await ethers.getSigners()
       const  Oracle = await ethers.getContractFactory("OracleStub", acc1)
       const  InvoiceMatcher = await ethers.getContractFactory("InvoiceMatcher", acc1)
       
       oracleContract  = await Oracle.deploy()
       await oracleContract.waitForDeployment()
       oracleContractAddress = await oracleContract.getAddress()

       invoiceContract  = await InvoiceMatcher.deploy(oracleContractAddress, 10)
       await invoiceContract.waitForDeployment()
       invoiceContractAddress =  await invoiceContract.getAddress()
     })

   

    it("invoice created", async () => {
        const  tx = await invoiceContract.newInvoce("ipfs://123",acc2, 100000000000)
         await tx.wait();
        account2Address = await acc2.getAddress()
        await expect(tx, "not issued").to.emit(invoiceContract,"ImvoiceIssued").withArgs(1,account2Address )
        const url = await invoiceContract.getInvoiceUrl(1)
         expect(url, "url is not correct").to.equal("ipfs://123")
        const payed = await invoiceContract.isPayed(1)
        expect(payed,"invoice not payed").to.equal(false)


    })

    it("invoice klay price is correct", async () => {
        const  tx = await invoiceContract.newInvoce("ipfs://123",acc2, 100000000000)
        await tx.wait();
        const price = await invoiceContract.getInvoiceKlayPrice(1)
        expect(price).to.equal(172769441)
    })

    it("invoice sum is correct", async () => {
        const sum = await invoiceContract.calcSum(100000000000, 172769441)
        expect(sum).to.equal(578000000000)
    })

    it("invoice payed", async () => {
        const  tx = await invoiceContract.newInvoce("ipfs://123",acc2, 100000000000)
        await tx.wait();
        const price = await invoiceContract.getInvoiceKlayPrice(1)
        const sum = await invoiceContract.calcSum(100000000000, price)

        const  payTx = await invoiceContract.connect(acc2).pay(1, {value:sum})
        await payTx.wait();
        await expect(payTx, "not issued").to.emit(invoiceContract,"Paid");
        
        const payed = await invoiceContract.isPayed(1)
        expect(payed,"invoice not payed").to.equal(true)
        
        const totalTaxBakance = await invoiceContract.totalTaxBalance()
        expect(totalTaxBakance,"bad tax balance").to.equal(0)

        const bal = await invoiceContract.balances(acc1)
        expect(bal, "bad user balance").to.equal(sum)

        const usersBalance = await invoiceContract.usersBalance()
        expect(usersBalance, "bad user balance").to.equal(sum)

    })

    it("withdraw balance  ", async () => {
        const  tx = await invoiceContract.connect(acc2).newInvoce("ipfs://123",acc3, 100000000000)
        await tx.wait();
        const price = await invoiceContract.getInvoiceKlayPrice(1)
        const sum = await invoiceContract.calcSum(100000000000, price)
        const  payTx = await invoiceContract.connect(acc3).pay(1, {value:sum})
        await payTx.wait();
        
        const wtx = await invoiceContract.connect(acc2).withdrawBalance()
        await expect(()=>wtx).to.changeEtherBalance(acc2, 520200000000)

        const totalTaxBakance = await invoiceContract.totalTaxBalance()
        expect(totalTaxBakance,"bad tax balance").to.equal(57800000000)
    })

    

    //57800000000

     
})