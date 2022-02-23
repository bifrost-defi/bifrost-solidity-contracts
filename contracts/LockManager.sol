// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LockManager is Initializable {
    // @dev Orders of variables must not be changed!
    // Only additions to the end allowed.
    // See https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies
    address internal usdcContractAddress;

    bytes4 private ERC20TransferSelector;

    mapping(address => uint256) locked;
    mapping(string => bool) operations;

    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    event USDCLocked(address user, uint256 amount, string destination);

    event USDCUnlocked(address user, uint256 amount);

    event AVAXLocked(address user, uint256 amount, string destination);

    event AVAXUnlocked(address user, uint256 amount);

    // @dev initialize acts like constructor.
    // This function can only be called once.
    function initialize(address usdcContract) public initializer {
        usdcContractAddress = usdcContract;

        ERC20TransferSelector = bytes4(
            keccak256(bytes("transferFrom(address,address,uint256)"))
        );
    }

    function lockUSDC(uint256 _amount, string calldata _destination)
        external
        returns (bool success)
    {
        require(_amount > 0, "Amount must be greater than 0");

        _transferERC20(usdcContractAddress, msg.sender, address(this), _amount);

        emit USDCLocked(msg.sender, _amount, _destination);

        return true;
    }

    function unlockUSDC(uint256 _amount) external returns (bool success) {
        require(_amount > 0, "Amount must be greater than 0");

        _transferERC20(usdcContractAddress, address(this), msg.sender, _amount);

        emit USDCUnlocked(msg.sender, _amount);

        return true;
    }

    function lockAVAX(string calldata _destination)
        public
        payable
        returns (bool success)
    {
        require(msg.value > 0, "Value must be greater than 0");

        locked[msg.sender] = msg.value;

        emit AVAXLocked(msg.sender, msg.value, _destination);

        return true;
    }

    function unlockAVAX(uint256 _amount) public returns (bool success) {
        require(locked[msg.sender] >= _amount, "Insufficient funds");

        locked[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit AVAXUnlocked(msg.sender, _amount);

        return true;
    }

    function _transferERC20(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) private {
        bytes memory fn = abi.encodeWithSelector(
            ERC20TransferSelector,
            _from,
            _to,
            _amount
        );

        (bool success, bytes memory data) = _token.call(fn);

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Transfer failed"
        );
    }
}
