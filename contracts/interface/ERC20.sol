// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hardhat/console.sol";

contract ERC20 {
    // State variables
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Mappings for balances and allowances
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Custom errors for failure cases
    error InvalidSender(address sender);
    error InvalidReceiver(address receiver);
    error InsufficientBalance(address sender, uint256 balance, uint256 amount);
    error InsufficientAllowance(address spender, uint256 allowance, uint256 amount);
    error InvalidApprover(address owner);
    error InvalidSpender(address spender);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Constructor to initialize name, symbol, and decimals
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        // _decimals = decimals_;
    }

    // Public view functions
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        console.log(spender, _allowances[owner][spender]);
        return _allowances[owner][spender];
    }

    // Transfer function
    function transfer(address to, uint256 amount) public returns (bool) {
        address sender = msg.sender;
        _transfer(sender, to, amount);
        return true;
    }

    // Approve function to set allowance for a spender
    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    // Transfer from function that uses the allowance mechanism
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // Internal transfer logic
    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) {
            revert InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert InvalidReceiver(address(0));
        }

        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert InsufficientBalance(from, fromBalance, amount);
        }

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    // Internal mint function to create tokens
    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) {
            revert InvalidReceiver(address(0));
        }

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Internal burn function to destroy tokens
    function _burn(address account, uint256 amount) internal {
        if (account == address(0)) {
            revert InvalidSender(address(0));
        }

        uint256 accountBalance = _balances[account];
        if (accountBalance < amount) {
            revert InsufficientBalance(account, accountBalance, amount);
        }

        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    // Internal approve function
    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0)) {
            revert InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert InvalidSpender(address(0));
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Internal function to spend allowance
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance < amount) {
            revert InsufficientAllowance(spender, currentAllowance, amount);
        }

        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
    }
}
