// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Token.sol";

contract Bridge is Ownable {
    using SafeMath for uint256;

    bytes4 private ERC20MintSelector;

    address[] private oracles;
    mapping(address => bool) private isOracle;
    mapping(uint32 => address) private tokens;

    event Lock(
        address indexed from,
        uint256 value,
        string destAddress,
        int256 destChain
    );
    event Unlock(address indexed to, uint256 value);

    event BurnERC20(
        address indexed token,
        address indexed from,
        uint256 value,
        string destAddress
    );
    event MintERC20(uint32 coinId, address indexed to, uint256 value);

    event TokenCreated(uint32 coinId, address tokenAddress);

    modifier onlyOracle() {
        require(isOracle[msg.sender], "Caller is not an oracle");
        _;
    }

    constructor(address[] memory _oracles) {
        _updateOracles(_oracles);

        ERC20MintSelector = bytes4(keccak256(bytes("mint(address,uint256)")));
    }

    function createToken(
        string memory _name,
        string memory _symbol,
        uint32 _coinId
    ) external onlyOwner returns (bool success) {
        require(tokens[_coinId] == address(0), "Token already exists");

        Token token = new Token(_name, _symbol);
        tokens[_coinId] = address(token);

        emit TokenCreated(_coinId, address(token));

        return true;
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

    function mintERC20(
        uint32 _coinId,
        address _to,
        uint256 _amount
    ) external onlyOracle returns (bool success) {
        require(_amount > 0, "Amount must be greater than 0");
        require(tokens[_coinId] != address(0), "Token does not exist");

        _mintERC20(tokens[_coinId], _to, _amount);

        emit MintERC20(_coinId, _to, _amount);

        return true;
    }

    function _mintERC20(
        address _token,
        address _to,
        uint256 _amount
    ) private {
        bytes memory fn = abi.encodeWithSelector(
            ERC20MintSelector,
            _to,
            _amount
        );

        (bool success, bytes memory data) = _token.call(fn);

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Mint failed"
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
