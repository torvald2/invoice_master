const {ethers} = require("hardhat");

async function main() {

    const deployerAddr = "0x5670C12E00c3fc907e538066b23b7e3BcD5CeA9A";
    const deployer = await ethers.getSigner(deployerAddr);

    console.log(`Deploying contracts with the account: ${deployer.address}`);

  const sbt = await ethers.getContractFactory("InvoiceMatcher");
  const sbtContract = await sbt.deploy("0xbc884088e406422a3ef39aedd1c546de7ac4be7c",2);


  await sbtContract.waitForDeployment();
  let address = await sbtContract.getAddress();

console.log(`Congratulations! You have just successfully deployed your soul bound tokens.`);
console.log(`SBT contract address is ${address}. You can verify on https://baobab.scope.klaytn.com/account/${address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});