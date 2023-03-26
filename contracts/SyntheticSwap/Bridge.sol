// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Token.sol";
import "./interfaces/IBridgeToken.sol";

contract Bridge is Ownable {
    using SafeMath for uint256;

    address[] private oracles;
    mapping(address => bool) private isOracle;
    mapping(uint32 => address) private tokens;

    event Lock(
        address indexed from,
        uint256 value,
        uint32 destCoinId,
        string destAddress
    );
    event Unlock(address indexed to, uint256 value);

    event BurnERC20(
        address indexed from,
        uint256 value,
        uint32 destCoinId,
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
    }

    function createToken(
        string calldata _name,
        string calldata _symbol,
        uint32 _coinId
    ) external onlyOwner returns (bool success) {
        require(tokens[_coinId] == address(0), "Token already exists");

        Token token = new Token(_name, _symbol);
        tokens[_coinId] = address(token);

        emit TokenCreated(_coinId, address(token));

        return true;
    }

    function lock(
        string calldata _destAddress,
        uint32 _destCoinId
    ) external payable returns (bool success) {
        require(msg.value > 0, "Value must be greater than 0");

        emit Lock(msg.sender, msg.value, _destCoinId, _destAddress);

        return true;
    }

    function unlock(
        address payable _to,
        uint256 _amount
    ) external onlyOracle returns (bool success) {
        require(_amount > 0, "Amount must be greater than 0");

        (bool sent, ) = _to.call{value: _amount}("");

        require(sent, "Failed to transfer");

        emit Unlock(_to, _amount);

        return true;
    }

    function mintERC20(
        uint32 _destCoinId,
        address _to,
        uint256 _amount
    ) external onlyOracle returns (bool success) {
        require(_amount > 0, "Amount must be greater than 0");
        require(tokens[_destCoinId] != address(0), "Token does not exist");

        IBridgeToken(tokens[_destCoinId]).mint(_to, _amount);

        emit MintERC20(_destCoinId, _to, _amount);

        return true;
    }

    function burnERC20(
        uint32 _destCoinId,
        string calldata _destAddress,
        uint256 _amount
    ) external returns (bool success) {
        require(_amount > 0, "Amount must be greater than 0");

        IBridgeToken(tokens[_destCoinId]).burn(msg.sender, _amount);

        emit BurnERC20(msg.sender, _amount, _destCoinId, _destAddress);

        return true;
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
