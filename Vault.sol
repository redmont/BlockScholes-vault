// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract Vault {
    event Deposit(address user, address token, uint256 amount);
    event Withdraw(address user, address token, uint256 amount);
    event ETHWrapped(address user, uint256 amount);
    event ETHUnwrapped(address user, uint256 amount);

    mapping(address => mapping(address => uint256)) public balances;
    IWETH public immutable wETH;

    constructor(address _wETHAddr) {
        wETH = IWETH(_wETHAddr);
    }

    function depositETH() external payable {
        require(msg.value > 0, "Value must be greater than zero");
        balances[msg.sender][address(0)] += msg.value;
        emit Deposit(msg.sender, address(0), msg.value);
    }

    function deposit(address _token, uint256 _value) external {
        require(_value > 0, "Value must be greater than zero");
        IERC20(_token).transferFrom(msg.sender, address(this), _value);
        balances[msg.sender][_token] += _value;
        emit Deposit(msg.sender, _token, _value);
    }

    function withdrawETH(uint256 _value) external {
        require(balances[msg.sender][address(0)] >= _value, "Insufficient balance");
        balances[msg.sender][address(0)] -= _value;
        (bool success, ) = msg.sender.call{value: _value}("");
        require(success, "Transfer failed");
        emit Withdraw(msg.sender, address(0), _value);
    }

    function withdraw(address _token, uint256 _value) external {
        require(balances[msg.sender][_token] >= _value, "Insufficient balance");
        balances[msg.sender][_token] -= _value;
        IERC20(_token).transfer(msg.sender, _value);
        emit Withdraw(msg.sender, _token, _value);
    }

    function wrapETH(uint256 _amount) external {
        require(balances[msg.sender][address(0)] >= _amount, "Insufficient ETH");
        balances[msg.sender][address(0)] -= _amount;
        balances[msg.sender][address(wETH)] += _amount;
        wETH.deposit{value: _amount}();
        emit ETHWrapped(msg.sender, _amount);
    }

    function unwrapETH(uint256 _amount) external {
        require(balances[msg.sender][address(wETH)] >= _amount, "Insufficient wETH");
        balances[msg.sender][address(wETH)] -= _amount;
        balances[msg.sender][address(0)] += _amount;
        wETH.withdraw(_amount);
        emit ETHUnwrapped(msg.sender, _amount);
    }
}
