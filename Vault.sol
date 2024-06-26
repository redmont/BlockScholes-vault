// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH{
    function deposit() external payable;
    function withdraw(uint256) external;
}

//  //0x0000000000000000000000000000000000000000 - ETH address
    //0xfff9976782d46cc05630d1f6ebab18b2324d6b14 - WETH sepolia
    

contract Vault{

    event Deposit(address user, address token, uint256 amount);
    event Withdraw(address user, address token, uint256 amount);
    event ETHWrapped(address user, uint256 amount);
    event ETHUnwrapped(address user, uint256 amount);
    
    mapping(address=> mapping(address =>uint256)) public balances;
    address public wETHAddr;
    IWETH wETH;

    constructor(address _wETHAddr) {
        wETH = IWETH(_wETHAddr);
        wETHAddr = _wETHAddr;
    }

    function deposit(address _token, uint256 _value) external payable {
        require(_value>0, "value should be greater than zero");

        if(_token == address(0)){
            balances[msg.sender][address(0)] += msg.value;
        }
        else {
            IERC20(_token).transferFrom(msg.sender, address(this), _value);
            balances[msg.sender][_token] += _value;
        }
        emit Deposit(msg.sender, _token, _value);
    }

    function withdraw(address _token, uint256 _value) external payable{
        require(balances[msg.sender][_token] >= _value, "Insufficient balance");
        if(_token == address(0)){
            (bool success, ) = msg.sender.call{value:_value}("");
            require(success, "Transfer ETH Failed");
            balances[msg.sender][_token] -= _value;
        }
        else {
            IERC20(_token).transfer(msg.sender, _value);
            balances[msg.sender][_token] -= _value;
        }
        emit Withdraw(msg.sender, _token, _value);
    }
    function wrapETH(uint256 amount) external{
        require(balances[msg.sender][address(0)] >= amount, "Insuffient ETH");
        wETH.deposit{value:amount}();
        balances[msg.sender][address(0)] -= amount;
        balances[msg.sender][wETHAddr] += amount;
        emit ETHWrapped(msg.sender,amount);
    }

    function unwrapETH(uint256 amount) external{
        require(balances[msg.sender][wETHAddr] >= amount, "Insuffient wETH");
        wETH.withdraw(amount);
        balances[msg.sender][address(0)] += amount;
        balances[msg.sender][wETHAddr] -= amount;
        emit ETHUnwrapped(msg.sender,amount);
    }
}