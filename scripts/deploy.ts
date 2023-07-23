// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { Contract, ContractFactory } from 'ethers';
import { ethers, run } from 'hardhat';

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  //eslint-disable-next-line
  const TOKEN_ADDRESS = '0x26f15017176D7EEF0062d057533A610b803c39B3';
  //eslint-disable-next-line
  const GOVERNANCE_ADDRESS = '0x6066D7184434D83f3F77ae1a52E6ED97144B1137';
  //eslint-disable-next-line
  const STAKE_ADDRESS = '0x677887482b33264d5D3a484E1Ca5951372a3e061';

  // We get the contract to deploy
  const TokenName: string = 'Stake';
  const constructorArgs: Array<string | number | Array<string | number>> = [
    TOKEN_ADDRESS,
    GOVERNANCE_ADDRESS,
  ];
  const factory: ContractFactory = await ethers.getContractFactory(TokenName);
  const contract: Contract = await factory.deploy(...constructorArgs);
  await contract.deployed();
  console.log(TokenName + ' deployed to:', contract.address);

  await setTimeout(async () => {
    // verify contracts on explorer
    await run('verify:verify', {
      address: contract.address,
      constructorArguments: constructorArgs,
    });
  }, 1000 * 60); // 60 secs
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
