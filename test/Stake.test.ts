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
    token = await factory.deploy(BigNumber.from('100000000000000000000000000'));
    governance = await factory3.deploy(token.address);
    stake = await factory2.deploy(token.address, governance.address);
  });

  async function prepare(user: SignerWithAddress) {
    token.transfer(user.address, 100_000 * 10 ** 8);
    await token.connect(user).approve(governance.address, constants.MaxUint256);
    await token.connect(user).approve(stake.address, constants.MaxUint256);
  }

  it('stake + gov tests', async () => {
    const depositAmount = 10_000 * 10 ** 8;

    await expect(governance.voteProject(1, true)).to.revertedWithCustomError(
      governance,
      'NotApproved'
    );

    const now = Math.floor(+new Date() / 1000);

    await token.approve(governance.address, constants.MaxUint256);
    await token.approve(stake.address, constants.MaxUint256);
    await stake.addAprReward(BigNumber.from(100000 * 10 ** 8));

    await prepare(addresses[0]);

    await expect(
      governance.approveProject(
        1, //id
        24_000, //apr
        365 * days, // lockedTime
        now + 10 * days, // vote end time
        now + 40 * days, // stake end time,
        10_000, // refPercantage
        10_000 * 10 ** 8 //amountToBeCollect
      )
    ).to.revertedWithCustomError(governance, 'DidNotApplied');

    await expect(governance.applyProject())
      .to.emit(governance, 'ProjectApplied')
      .withArgs(1);

    await expect(
      stake.stake(1, depositAmount, owner.address)
    ).to.revertedWithCustomError(stake, 'ProjectIsNotPassedTheVoting');

    await expect(
      governance.approveProject(
        1, //id
        24_000, //apr
        365 * days, // lockedTime
        now + 10 * days, // vote end time
        now + 40 * days, // stake end time,
        10_000, // refPercantage
        10_000 * 10 ** 8 //amountToBeCollect
      )
    )
      .to.emit(governance, 'ProjectApproved')
      .withArgs(
        1, //id
        24_000, //apr
        365 * days, // lockedTime
        now + 10 * days, // vote end time
        now + 40 * days, // stake end time,
        10_000, // refPercantage
        10_000 * 10 ** 8 //amountToBeCollect
      );

    await expect(
      governance.approveProject(
        1, //id
        24_000, //apr
        365 * days, // lockedTime
        now + 10 * days, // vote end time
        now + 40 * days, // stake end time,
        10_000, // refPercantage
        10_000 * 10 ** 8 //amountToBeCollect
      )
    ).to.revertedWithCustomError(governance, 'AlreadyApproved');

    //-----------------------------------------------------------

    const minAmountToVote = await governance.minAmountToVote();

    await expect(governance.voteProject(1, true))
      .to.emit(governance, 'ProjectVoted')
      .withArgs(1, owner.address, true);

    await expect(governance.voteProject(1, true)).to.revertedWithCustomError(
      governance,
      'AlreadyVoted'
    );

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
      governance.connect(addresses[0]).voteProject(1, false)
    ).to.revertedWithCustomError(governance, 'VoteEnded');

    //************* */

    await expect(stake.stake(1, 0, owner.address)).to.revertedWithCustomError(
      stake,
      'AmountCantBeZero'
    );
    await stake.takeBackRemainingRewards(await stake.tokenAprReward());

    await expect(
      stake.stake(1, depositAmount, owner.address)
    ).to.revertedWithCustomError(stake, 'InsufficientReward');

    await stake.addAprReward(BigNumber.from(100000 * 10 ** 8));

    await expect(stake.stake(1, depositAmount, owner.address))
      .to.emit(stake, 'Staked')
      .withArgs(1, owner.address, depositAmount);

    await expect(
      stake.stake(1, depositAmount, owner.address)
    ).to.revertedWithCustomError(stake, 'ProjectCollectCompleted');

    await expect(stake.unstake(1)).to.revertedWithCustomError(
      stake,
      'StakeIsLocked'
    );

    await ethers.provider.send('evm_increaseTime', [365 * days + 1]);

    await expect(stake.unstake(1))
      .to.emit(stake, 'Unstaked')
      .withArgs(1, owner.address, (depositAmount * 124) / 100);

    await expect(
      stake.stake(1, depositAmount, owner.address)
    ).to.revertedWithCustomError(stake, 'StakeIsEnded');
    await ethers.provider.send('evm_increaseTime', [-375 * days - 2]);
  });

  it('refund', async () => {
    const depositAmount = 10_000 * 10 ** 8;

    const now = Math.floor(+new Date() / 1000);

    await token.approve(governance.address, constants.MaxUint256);
    await token.approve(stake.address, constants.MaxUint256);
    await stake.addAprReward(BigNumber.from(100000 * 10 ** 8));

    await prepare(addresses[0]);

    await expect(governance.applyProject())
      .to.emit(governance, 'ProjectApplied')
      .withArgs(1);

    await governance.approveProject(
      1, //id
      24_000, //apr
      365 * days, // lockedTime
      now + 10 * days, // vote end time
      now + 40 * days, // stake end time,
      10_000, // refPercantage
      10_000 * 10 ** 8 //amountToBeCollect
    );

    //-----------------------------------------------------------

    await expect(governance.voteProject(1, true))
      .to.emit(governance, 'ProjectVoted')
      .withArgs(1, owner.address, true);

    await ethers.provider.send('evm_increaseTime', [10 * days + 1]);

    await expect(stake.stake(1, depositAmount / 10, owner.address))
      .to.emit(stake, 'Staked')
      .withArgs(1, owner.address, depositAmount / 10);

    await expect(stake.refund(1)).to.be.revertedWithCustomError(
      stake,
      'ProjectIsNotFailedToCollectAmount'
    );
    await ethers.provider.send('evm_increaseTime', [365 * days + 1]);

    await expect(stake.unstake(1)).to.be.revertedWithCustomError(
      stake,
      'ProjectIsFailedToCollectAmount'
    );

    await expect(stake.refund(1))
      .to.emit(stake, 'Refund')
      .withArgs(1, owner.address, depositAmount / 10);

    await expect(stake.refund(1)).to.be.revertedWithCustomError(
      stake,
      'NoDeposit'
    );

    await expect(
      stake.stake(1, depositAmount, owner.address)
    ).to.revertedWithCustomError(stake, 'StakeIsEnded');

    await ethers.provider.send('evm_increaseTime', [-375 * days - 2]);
  });

  it('ref', async () => {
    const depositAmount = 10_000 * 10 ** 8;

    const now = Math.floor(+new Date() / 1000);

    await token.approve(governance.address, constants.MaxUint256);
    await token.approve(stake.address, constants.MaxUint256);
    await stake.addAprReward(BigNumber.from(100000 * 10 ** 8));

    await prepare(addresses[0]);

    await expect(governance.applyProject())
      .to.emit(governance, 'ProjectApplied')
      .withArgs(1);

    await governance.approveProject(
      1, //id
      24_000, //apr
      365 * days, // lockedTime
      now + 10 * days, // vote end time
      now + 40 * days, // stake end time,
      10_000, // refPercantage
      10_000 * 10 ** 8 //amountToBeCollect
    );

    //-----------------------------------------------------------

    await expect(governance.voteProject(1, true))
      .to.emit(governance, 'ProjectVoted')
      .withArgs(1, owner.address, true);

    await expect(governance.connect(addresses[0]).voteProject(1, true))
      .to.emit(governance, 'ProjectVoted')
      .withArgs(1, addresses[0].address, true);

    await ethers.provider.send('evm_increaseTime', [10 * days + 1]);

    await expect(
      stake
        .connect(addresses[0])
        .stake(1, depositAmount / 4, constants.AddressZero)
    ).to.be.revertedWithCustomError(stake, 'CantStakeWithoutRef');

    await expect(
      stake
        .connect(addresses[0])
        .stake(1, depositAmount / 4, addresses[0].address)
    ).to.be.revertedWithCustomError(stake, 'CantRefToYourself');

    await expect(
      stake
        .connect(addresses[0])
        .stake(1, depositAmount / 4, addresses[1].address)
    ).to.be.revertedWithCustomError(stake, 'RefererIsNoStaker');

    for (let index = 0; index < 2; index++) {
      await expect(
        stake.connect(addresses[0]).stake(1, depositAmount / 4, owner.address)
      )
        .to.emit(stake, 'Staked')
        .withArgs(1, addresses[0].address, depositAmount / 4);
    }

    for (let index = 0; index < 2; index++) {
      await expect(stake.stake(1, depositAmount / 4, owner.address))
        .to.emit(stake, 'Staked')
        .withArgs(1, owner.address, depositAmount / 4);
    }

    await ethers.provider.send('evm_increaseTime', [365 * days + 1]);

    for (let index = 0; index < 2; index++) {
      await expect(stake.connect(addresses[0]).unstake(1))
        .to.emit(stake, 'Unstaked')
        .withArgs(1, addresses[0].address, ((depositAmount / 4) * 124) / 100);
    }

    await expect(stake.unstake(1))
      .to.emit(stake, 'Unstaked')
      .withArgs(
        1,
        owner.address,
        ((depositAmount / 4) * 124) / 100 +
          //ref gain
          2 * (((depositAmount / 4) * 10) / 100)
      );

    await expect(stake.unstake(1))
      .to.emit(stake, 'Unstaked')
      .withArgs(1, owner.address, ((depositAmount / 4) * 124) / 100);

    await ethers.provider.send('evm_increaseTime', [-375 * days - 2]);
  });
});
