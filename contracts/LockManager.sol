// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LockManager is Initializable {
  // @dev Orders of variables must not be changed!
  // Only additions to the end allowed. 
  // See https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies
  mapping(address => uint256) locked; 
  
  using SafeMathUpgradeable for uint256;
  using ECDSAUpgradeable for bytes32;

  // @dev initialize acts like constructor.
  // This function can only be called once. 
  function initialize() public initializer {

  }

  function lock() public payable {
    require(msg.value > 0, "Not enough amount");
    locked[msg.sender] = msg.value;
  }
}
