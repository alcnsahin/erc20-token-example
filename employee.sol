// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol"; // console Library

struct Employee {
    string name;
    uint256 balance;
    bool isActive;
}

contract EAMToken is ERC20, ERC20Capped, ERC20Burnable, Ownable {
    event LoanEvent(address indexed from, address indexed to, uint256 value);

    uint256 public initialMintValue = 500;
    
    mapping(address => Employee) private _employees;

    constructor(uint256 cap)
        ERC20("EAMToken", "EAM")
        ERC20Capped(cap)
        Ownable(msg.sender)
    {
        super._mint(msg.sender, initialMintValue);
    }

    function getOwner() public view returns(address) {
        return owner();
    }

    function mint(uint256 amount) onlyOwner public {
        require(msg.sender == this.owner(), "You are not authorized!");
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");

        super._mint(msg.sender, amount);
    }

    function transfer(address to, uint256 amount) onlyOwner public override returns(bool){
        // onlyOwner
        require(msg.sender != address(0), "Transfer from the zero address is not allowed!");
        require(to != address(0), "You cannot transfer to zero address!");

        uint256 senderBalance = balanceOf(msg.sender);
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        _employees[to].balance += amount;
        _transfer(msg.sender, to, amount);
        return true;
    }

    function loan(address to, uint256 amount) external virtual {
        require(msg.sender != this.owner() && to != this.owner(), "Owner cannot use this function!");
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_employees[msg.sender].balance > amount, "ERC20: transfer amount exceeds balance");
        require(_employees[msg.sender].isActive, "From account is not registered");
        require(_employees[to].isActive, "To account is not registered");

        _employees[msg.sender].balance -= amount;
        _employees[to].balance += amount;

        _transfer(msg.sender, to, amount);

        emit LoanEvent(msg.sender, to, amount);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }

    function getEmployee(address employeeAddress) public view returns (Employee memory) {
        return _employees[employeeAddress];
    }

    function addEmployee(address employeeAddress, string memory name) public onlyOwner {
        require(employeeAddress != this.owner(), "Owner Address can not added");
        require(!_employees[employeeAddress].isActive, "Account is already registered");

        _employees[employeeAddress] = Employee(name, 0, true);
    }

    function removeEmployee(address employeeAddress) isEmployee(employeeAddress) onlyOwner public {
        require(employeeAddress != this.owner(), "Owner Address can not removed!");
        require(_employees[employeeAddress].isActive, "Employee could not found!");
        delete _employees[employeeAddress];
    }

    function distributeRewards(address[] memory rewardedAccounts, uint256 amount) rewardRestriction(rewardedAccounts, amount) onlyOwner public virtual {
        for (uint8 i = 0; i < rewardedAccounts.length; i++) {

            _employees[rewardedAccounts[i]].balance += amount;
            _transfer(msg.sender, rewardedAccounts[i], amount);
        }
    }

    modifier rewardRestriction(address[] memory rewardedAccounts, uint256 amount){
        uint256 totalRewards = rewardedAccounts.length * amount;
        require(totalRewards <= 10 ether, "In a single call, you can distribute maks 10 ether!");
        _;
    }

    modifier isEmployee(address account){
        require(_employees[account].isActive, "Unknown account!");
        _;
    }
    
}
