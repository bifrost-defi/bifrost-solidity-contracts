// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LockManager is Initializable, OwnableUpgradeable {
  // @dev Orders of variables must not be changed!
  // Only additions to the end allowed. 
  // See https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies
  bytes4 private ERC20TransferSelector;

  mapping(address => uint256) locked; 
  mapping(address => Operation) operations;
  
  address internal usdcContractAddress;

  using SafeMathUpgradeable for uint256;
  using ECDSAUpgradeable for bytes32;

   event PreCommit(
    address user,
    string destination
  );

  event USDCLocked(
    address user,
    uint256 amount,
    string destination,
    string operationID
  );

  event USDCUnlocked(
    address user,
    uint256 amount
  );

  event AVAXLocked(
    address user,
    uint256 amount,
    string destination,
    string operationID
  );

  event AVAXUnlocked(
    address user,
    uint256 amount
  );

  struct Operation {
    bool approved;
    string id;
    uint256 amount;
    string destination;
  }

  modifier operationApproved {
    require(
      operations[msg.sender].approved,
      "Operation was not approved"
    );
    require(
      keccak256(bytes(operations[msg.sender].id)) != keccak256(bytes("")),
      "Operation has no id"
    );
    _;
  }

  // @dev initialize acts like constructor.
  // This function can only be called once. 
  function initialize() public initializer {
    __Ownable_init();

    usdcContractAddress = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    ERC20TransferSelector = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
  }

  function createOperation(uint256 _amount, string calldata _destination) public {
    require(_amount > 0, "Amount must be greater than 0");
    
    operations[msg.sender] = Operation(false, "", _amount, _destination);

    emit PreCommit(msg.sender, _destination);
  }

  function approve(string memory _id, address _user, uint256 _amount, string calldata _destination) public onlyOwner {
    Operation memory op = operations[_user];

    require(!op.approved, "Operation already approved");
    require(keccak256(bytes(op.id)) == keccak256(bytes("")), "Operation id is not empty");
    require(op.amount == _amount, "Operation amount has changed");
    require(keccak256(bytes(op.destination)) == keccak256(bytes(_destination)), "Operation destination has changed");

    operations[msg.sender].approved = true;
    operations[msg.sender].id = _id;
  }

  function lockUSDC(uint256 _amount, string calldata _destination) operationApproved external returns (bool success) {
    require(_amount > 0, "Amount must be greater than 0");

    _transferERC20(usdcContractAddress, msg.sender, address(this), _amount);

    emit USDCLocked(msg.sender, _amount, _destination, operations[msg.sender].id);

    delete operations[msg.sender];

    return true;
  }

  function unlockUSDC(uint256 _amount) external returns (bool success) {
    require(_amount > 0, "Amount must be greater than 0");

    _transferERC20(usdcContractAddress, address(this), msg.sender, _amount);

    emit USDCUnlocked(msg.sender, _amount);

    return true;
  }

  function lockAVAX(string calldata _destination) operationApproved public payable returns (bool success) {
    require(msg.value > 0, "Value must be greater than 0");

    locked[msg.sender] = msg.value;

    emit AVAXLocked(msg.sender, msg.value, _destination, operations[msg.sender].id);

    delete operations[msg.sender];

    return true;
  }

  function unlockAVAX(uint256 _amount) public returns (bool success) {
    require(locked[msg.sender] >= _amount, "Insufficient funds");

    locked[msg.sender] -= _amount;
    payable(msg.sender).transfer(_amount);

    emit AVAXUnlocked(msg.sender, _amount);

    return true;
  }

  function _transferERC20(address _token, address _from, address _to, uint256 _amount) private {
    bytes memory fn = abi.encodeWithSelector(ERC20TransferSelector, _from, _to, _amount);

    (bool success, bytes memory data) = _token.call(fn);

    require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
  }
}
