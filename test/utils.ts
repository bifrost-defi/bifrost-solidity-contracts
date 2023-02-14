import { encode } from "rlp";
import { ethers } from "ethers";

export const computeContractAddress = (creator: string, nonce: number) => {
  const encoded: any = encode([creator, ethers.utils.hexlify(nonce)]);
  const hash: string = ethers.utils.keccak256(encoded)!;
  const address = hash.substring(26);

  return ethers.utils.getAddress("0x" + address);
};
