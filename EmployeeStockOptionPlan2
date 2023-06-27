// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract EmployeeStockOptionPlan {
    address private owner; // Company address

    struct Employee {
        uint256 grantAmount; // Number of granted options
        uint256 vestedAmount; // Number of vested options
        uint256 exercisedAmount; // Number of exercised options
        uint256 vestingStart; // Vesting start timestamp
        uint256 vestingDuration; // Vesting duration in seconds
        address transferTo; // Address to which vested options can be transferred
    }

    mapping(address => Employee) private employees;
    IERC20 private token; // Reference to the ERC20 token contract

    event StockOptionsGranted(address indexed employee, uint256 amount);
    event VestingScheduleSet(address indexed employee, uint256 start, uint256 duration);
    event OptionsExercised(address indexed employee, uint256 amount);
    event OptionsTransferred(address indexed from, address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier onlyEmployee() {
        require(employees[msg.sender].grantAmount > 0, "You are not an authorized employee.");
        _;
    }

    constructor(address tokenAddress) {
        owner = msg.sender;
        token = IERC20(tokenAddress); // Initialize the ERC20 token contract
    }

    function grantStockOptions(address employee, uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid option amount.");
        employees[employee].grantAmount += amount;
        emit StockOptionsGranted(employee, amount);
    }

    function setVestingSchedule(address employee, uint256 start, uint256 duration) external onlyOwner {
        require(employees[employee].grantAmount > 0, "Employee does not have any granted options.");
        require(start > block.timestamp, "Vesting start must be in the future.");
        require(duration > 0, "Invalid vesting duration.");

        employees[employee].vestingStart = start;
        employees[employee].vestingDuration = duration;
        emit VestingScheduleSet(employee, start, duration);
    }

    function exerciseOptions(uint256 amount) external onlyEmployee {
        Employee storage employee = employees[msg.sender];
        require(employee.vestedAmount >= amount, "Insufficient vested options.");

        employee.vestedAmount -= amount;
        employee.exercisedAmount += amount;
        emit OptionsExercised(msg.sender, amount);
    }

    function getVestedOptions(address employee) external view returns (uint256) {
        return employees[employee].vestedAmount;
    }

    function getExercisedOptions(address employee) external view returns (uint256) {
        return employees[employee].exercisedAmount;
    }

    function transferOptions(address to, uint256 amount) external onlyEmployee {
        Employee storage fromEmployee = employees[msg.sender];
        Employee storage toEmployee = employees[to];

        require(fromEmployee.vestedAmount >= amount, "Insufficient vested options.");
        require(toEmployee.transferTo == address(0), "The receiver is not eligible to receive options.");

        fromEmployee.vestedAmount -= amount;
        toEmployee.vestedAmount += amount;
        toEmployee.transferTo = to;

        if (fromEmployee.vestedAmount == 0) {
            fromEmployee.transferTo = address(0);
        }

        emit OptionsTransferred(msg.sender, to, amount);
    }

    function transferERC20(address to, uint256 amount) external onlyEmployee {
        require(amount > 0, "Invalid transfer amount.");

        Employee storage fromEmployee = employees[msg.sender];
        require(fromEmployee.vestedAmount >= amount, "Insufficient vested options.");

        fromEmployee.vestedAmount -= amount;
        require(token.transfer(to, amount), "ERC20 transfer failed.");

        emit OptionsTransferred(msg.sender, to, amount);
    }

    function withdrawERC20(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid withdrawal amount.");

        uint256 contractBalance = token.balanceOf(address(this));
        require(amount <= contractBalance, "Insufficient contract balance.");

        require(token.transfer(to, amount), "ERC20 transfer failed.");
    }
}
