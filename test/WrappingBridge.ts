import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { WrappingBridge } from "../typechain-types";

describe("WrappingBridge", () => {
  let Bridge: WrappingBridge;
  let accounts: SignerWithAddress[];

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    const factory = await ethers.getContractFactory("WrappingBridge");
    Bridge = await factory.deploy([accounts[0].address]);

    await Bridge.deployed();
  });

  it("should lock eth and emit event", async () => {
    const value = 10;
    const destAddress = accounts[1].address;
    const destChain = 1;

    const tx = await Bridge.lock(destAddress, destChain, { value });
    const receipt = await tx.wait();

    const event = receipt.events?.[0];

    expect(event?.event).to.equal("Lock");
    expect(event?.args?.from).to.equal(accounts[0].address);
    expect(event?.args?.value).to.equal(value);
    expect(event?.args?.destAddress).to.equal(destAddress);
    expect(event?.args?.destChain).to.equal(destChain);
  });

  it("should unlock eth and emit event", async () => {
    const value = 10;
    const destAddress = accounts[1].address;

    const oldBalance = await accounts[1].getBalance();

    // Lock some eth to fund contract.
    const tx1 = await Bridge.lock(destAddress, 1, { value });
    await tx1.wait();

    const tx2 = await Bridge.unlock(destAddress, value);
    const receipt = await tx2.wait();

    const newBalance = await accounts[1].getBalance();
    const event = receipt.events?.[0];

    expect(newBalance.sub(oldBalance)).to.equal(value);
    expect(event?.event).to.equal("Unlock");
    expect(event?.args?.to).to.equal(destAddress);
    expect(event?.args?.value).to.equal(value);
  });
});
