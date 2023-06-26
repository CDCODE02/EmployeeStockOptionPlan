// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title EmployeeStockOptionPlan
 * @dev A smart contract for managing an Employee Stock Option Plan.
 * This contract allows Zarttech to grant stock options to employees,
 * set a vesting schedule for the options, exercise vested options,
 * track vested and exercised options, and transfer vested options.
 */
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

    event StockOptionsGranted(address indexed employee, uint256 amount); // The StockOptionsGranted event
    event VestingScheduleSet(address indexed employee, uint256 start, uint256 duration); // The VestingScheduleSet event
    event OptionsExercised(address indexed employee, uint256 amount); // The OptionsExercised event
    event OptionsTransferred(address indexed from, address indexed to, uint256 amount); // The OptionsTransferred event
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
    
    modifier onlyEmployee() {
        require(employees[msg.sender].grantAmount > 0, "You are not an authorized employee.");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Grant stock options to an employee.
     * @param employee The address of the employee.
     * @param amount The number of options to be granted.
     */
    function grantStockOptions(address employee, uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid option amount.");
        employees[employee].grantAmount += amount;
        emit StockOptionsGranted(employee, amount);
    }
    
    /**
     * @dev Set the vesting schedule for an employee's options.
     * @param employee The address of the employee.
     * @param start The vesting start timestamp.
     * @param duration The vesting duration in seconds.
     */
    function setVestingSchedule(address employee, uint256 start, uint256 duration) external onlyOwner {
        require(employees[employee].grantAmount > 0, "Employee does not have any granted options.");
        require(start > block.timestamp, "Vesting start must be in the future.");
        require(duration > 0, "Invalid vesting duration.");
        
        employees[employee].vestingStart = start;
        employees[employee].vestingDuration = duration;
        emit VestingScheduleSet(employee, start, duration);
    }
    
    /**
     * @dev Exercise vested options.
     * @param amount The number of options to be exercised.
     */
    function exerciseOptions(uint256 amount) external onlyEmployee {
        Employee storage employee = employees[msg.sender];
        require(employee.vestedAmount >= amount, "Insufficient vested options.");
        
        employee.vestedAmount -= amount;
        employee.exercisedAmount += amount;
        emit OptionsExercised(msg.sender, amount);
    }
    
    /**
     * @dev Get the number of vested options for an employee.
     * @param employee The address of the employee.
     * @return The number of vested options.
     */
    function getVestedOptions(address employee) external view returns (uint256) {
        return employees[employee].vestedAmount;
    }
    
    /**
     * @dev Get the number of exercised options for an employee.
     * @param employee The address of the employee.
     * @return The number of exercised options.
     */
    function getExercisedOptions(address employee) external view returns (uint256) {
        return employees[employee].exercisedAmount;
    }
    
    /**
     * @dev Transfer vested options to another employee.
     * @param to The address of the receiver.
     * @param amount The number of options to be transferred.
     */
    function transferOptions(address to, uint256 amount) external onlyEmployee {
        Employee storage fromEmployee = employees[msg.sender];
        Employee storage toEmployee = employees[to];
        
        require(fromEmployee.vestedAmount >= amount, "Insufficient vested options.");
        require(toEmployee.transferTo == address(0), "The receiver is not eligible to receive options.");
        
        fromEmployee.vestedAmount -= amount;
        toEmployee.vestedAmount += amount;
        toEmployee.transferTo = to;
        
        // Reset transferred options to prevent further transfers
        if (fromEmployee.vestedAmount == 0) {
            fromEmployee.transferTo = address(0);
        }
        
        emit OptionsTransferred(msg.sender, to, amount);
    }
}
