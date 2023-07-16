import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, constants } from 'ethers';
import { ethers } from 'hardhat';

import type {
  Stake,
  Stake__factory,
  Governance,
  Governance__factory,
  NxtuToken,
  NxtuToken__factory,
  // eslint-disable-next-line node/no-missing-import
} from '../typechain-types';

const name: string = 'NxtuToken';
const name2: string = 'Stake';
const name3: string = 'Governance';
const days = 86400;

describe(name, () => {
  let factory: NxtuToken__factory;
  let factory2: Stake__factory;
  let factory3: Governance__factory;

  let token: NxtuToken;
  let stake: Stake;
  let governance: Governance;

  let owner: SignerWithAddress;
  let addresses: SignerWithAddress[];

  // hooks
  before(async () => {
    [owner, ...addresses] = await ethers.getSigners();
    factory = await ethers.getContractFactory(name);
    factory2 = await ethers.getContractFactory(name2);
    factory3 = await ethers.getContractFactory(name3);
    stake;
    owner;
    addresses;
  });

  beforeEach(async () => {
    token = await factory.deploy(BigNumber.from('100000000000000000000000'));
    governance = await factory3.deploy(token.address);
    stake = await factory2.deploy(token.address, governance.address);
  });

  it('stake + gov tests', async () => {
    const depositAmount = 1000 * 10 ** 8;

    await expect(
      governance.voteProject(1, true, depositAmount)
    ).to.revertedWithCustomError(governance, 'NotApproved');

    const now = Math.floor(+new Date() / 1000);

    await token.approve(governance.address, constants.MaxUint256);
    await token.approve(stake.address, constants.MaxUint256);
    await stake.addAprReward(BigNumber.from(100000 * 10 ** 8));

    await expect(
      governance.approveProject(
        1,
        'name',
        'desc',
        'url',
        24_000, //apr
        365 * days, // lockedTime
        now + 10 * days, // vote end time
        now + 40 * days // stake end time
      )
    ).to.revertedWithCustomError(governance, 'DidNotApplied');

    await expect(governance.applyProject())
      .to.emit(governance, 'ProjectApplied')
      .withArgs(1);

    await expect(stake.stake(1, depositAmount)).to.revertedWithCustomError(
      stake,
      'ProjectIsNotPassedTheVoting'
    );

    await expect(
      governance.approveProject(
        1,
        'name',
        'desc',
        'url',
        24_000, //apr
        365 * days, // lockedTime
        now + 10 * days, // vote end time
        now + 40 * days // stake end time
      )
    )
      .to.emit(governance, 'ProjectApproved')
      .withArgs(
        1,
        'name',
        'desc',
        'url',
        24_000, //apr
        365 * days, // lockedTime
        now + 10 * days, // vote end time
        now + 40 * days // stake end time
      );

    await expect(
      governance.approveProject(
        1,
        'name',
        'desc',
        'url',
        24_000, //apr
        365 * days, // lockedTime
        now + 10 * days, // vote end time
        now + 40 * days // stake end time
      )
    ).to.revertedWithCustomError(governance, 'AlreadyApproved');

    //-----------------------------------------------------------

    await expect(governance.voteProject(1, true, 0)).to.revertedWithCustomError(
      governance,
      'LessThanMinAmount'
    );

    const minAmountToVote = await governance.minAmountToVote();

    await expect(governance.voteProject(1, true, minAmountToVote))
      .to.emit(governance, 'ProjectVoted')
      .withArgs(1, owner.address, true);

    await expect(
      governance.voteProject(1, true, minAmountToVote)
    ).to.revertedWithCustomError(governance, 'AlreadyVoted');

    //-----------------------------------------------------------

    await expect(stake.unstake(1)).to.revertedWithCustomError(
      stake,
      'NoDeposit'
    );

    await ethers.provider.send('evm_increaseTime', [10 * days + 1]);

    //************* */

    await token.mint(addresses[0].address, minAmountToVote);

    await token
      .connect(addresses[0])
      .approve(governance.address, constants.MaxUint256);

    await expect(
      governance.connect(addresses[0]).voteProject(1, false, depositAmount)
    ).to.revertedWithCustomError(governance, 'VoteEnded');

    //************* */

    await expect(stake.stake(1, 0)).to.revertedWithCustomError(
      stake,
      'AmountCantBeZero'
    );

    await expect(stake.stake(1, depositAmount))
      .to.emit(stake, 'Staked')
      .withArgs(1, owner.address, depositAmount);

    await stake.takeBackRemainingRewards(await stake.tokenAprReward());

    await expect(stake.stake(1, depositAmount)).to.revertedWithCustomError(
      stake,
      'InsufficientReward'
    );

    await expect(stake.unstake(1)).to.revertedWithCustomError(
      stake,
      'StakeIsLocked'
    );

    await ethers.provider.send('evm_increaseTime', [365 * days + 1]);

    await expect(stake.unstake(1))
      .to.emit(stake, 'Unstaked')
      .withArgs(1, owner.address, (depositAmount * 124) / 100);

    await expect(stake.stake(1, depositAmount)).to.revertedWithCustomError(
      stake,
      'StakeIsEnded'
    );
  });
});
