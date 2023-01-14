// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WrappingBridge is Ownable {
    using SafeMath for uint256;

    bytes4 private ERC20TransferSelector;

    address[] private oracles;
    mapping(address => bool) private isOracle;

    event Lock(
        address indexed from,
        uint256 value,
        string destAddress,
        int256 destChain
    );
    event LockERC20(
        address indexed token,
        address indexed from,
        uint256 value,
        string destAddress
    );
    event Unlock(address indexed to, uint256 value);
    event UnlockERC20(address indexed token, address indexed to, uint256 value);

    modifier onlyOracle() {
        require(isOracle[msg.sender], "Caller is not an oracle");
        _;
    }

    constructor(address[] memory _oracles) {
        _updateOracles(_oracles);

        ERC20TransferSelector = bytes4(
            keccak256(bytes("transferFrom(address,address,uint256)"))
        );
    }

    function lock(string calldata _destAddress, int256 _destChain)
        external
        payable
        returns (bool success)
    {
        require(msg.value > 0, "Value must be greater than 0");

        emit Lock(msg.sender, msg.value, _destAddress, _destChain);

        return true;
    }

    function lock(
        address _token,
        uint256 _amount,
        string calldata _destAddress
    ) external returns (bool success) {
        require(_amount > 0, "Amount must be greater than 0");

        _transferERC20(_token, msg.sender, address(this), _amount);

        emit LockERC20(_token, msg.sender, _amount, _destAddress);

        return true;
    }

    function unlock(address payable _to, uint256 _amount)
        external
        onlyOracle
        returns (bool success)
    {
        require(_amount > 0, "Amount must be greater than 0");

        (bool sent, ) = _to.call{value: _amount}("");

        require(sent, "Failed to transfer");

        emit Unlock(_to, _amount);

        return true;
    }

    function unlock(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOracle returns (bool success) {
        require(_amount > 0, "Amount must be greater than 0");

        _transferERC20(_token, address(this), _to, _amount);

        emit UnlockERC20(_token, _to, _amount);

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

    function _updateOracles(address[] memory _newOracles) private {
        for (uint256 i = 0; i < oracles.length; i++) {
            isOracle[oracles[i]] = false;
        }

        for (uint256 i = 0; i < _newOracles.length; i++) {
            require(_newOracles[i] != address(0), "Invalid oracle address");
            require(!isOracle[_newOracles[i]], "Duplicate oracle");
            isOracle[_newOracles[i]] = true;
        }

        oracles = _newOracles;
    }
}
