// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { Contract, ContractFactory, constants } from 'ethers';
import { ethers, run } from 'hardhat';
import type {
  Stake,
  Stake__factory,
  Governance,
  Governance__factory,
  NxtuToken,
  NxtuToken__factory,
  // eslint-disable-next-line node/no-missing-import
} from '../typechain-types';
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  //eslint-disable-next-line
  const TOKEN_ADDRESS = '0x6066D7184434D83f3F77ae1a52E6ED97144B1137';
  //eslint-disable-next-line
  const GOVERNANCE_ADDRESS = '0x677887482b33264d5D3a484E1Ca5951372a3e061';
  //eslint-disable-next-line
  const STAKE_ADDRESS = '0x374D25C2E5348fd123159A91F61e9BAea93E61Cc';

  const deploy = false;
  if (deploy) {
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
  } else {
    const days = 86400;
    const now = Math.floor(+new Date() / 1000);

    const tokenFactory: NxtuToken__factory = await ethers.getContractFactory(
      'NxtuToken'
    );
    const token: NxtuToken = await tokenFactory.attach(TOKEN_ADDRESS);

    const GovernanceFactory: Governance__factory =
      await ethers.getContractFactory('Governance');
    const governance: Governance = await GovernanceFactory.attach(
      GOVERNANCE_ADDRESS
    );
    const StakeFactory: Stake__factory = await ethers.getContractFactory(
      'Governance'
    );
    const stake: Stake = await StakeFactory.attach(STAKE_ADDRESS);
    stake;
    token;
    now;
    days;
    constants.AddressZero;
    // await governance.applyProject();

    // await token.approve(governance.address, constants.MaxUint256);
    // await token.approve(stake.address, constants.MaxUint256);
    // await stake.addAprReward(100000 * 10 ** 8);

    // await governance.approveProject(
    //   1, //id
    //   24_000, //apr
    //   1 * days, // lockedTime
    //   now + 1 * days, // vote end time
    //   now + 4 * days, // stake end time,
    //   10_000, // refPercantage
    //   10_000 * 10 ** 8 //amountToBeCollect
    // );

    await governance.voteProject(1, true);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
