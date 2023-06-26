pragma solidity ^0.8.0;

contract EmployeeStockOptionPlan {
    address private owner;

    struct VestingSchedule {
        uint256 cliffDuration;
        uint256 totalVestingDuration;
        uint256 startTime;
        uint256 totalOptions;
        uint256 vestedOptions;
        uint256 exercisedOptions;
        uint256[] monthlyVesting;
    }

    mapping(address => VestingSchedule) private vestingSchedules;

    event StockOptionsGranted(address indexed employee, uint256 amount);
    event VestingScheduleSet(address indexed employee, uint256 cliffDuration, uint256 totalVestingDuration);
    event OptionsExercised(address indexed employee, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier onlyEmployee() {
        require(vestingSchedules[msg.sender].totalOptions > 0, "Only employees can call this function");
        _;
    }

    function grantStockOptions(address employee, uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(vestingSchedules[employee].totalOptions == 0, "Employee already has stock options");

        vestingSchedules[employee].totalOptions = amount;

        emit StockOptionsGranted(employee, amount);
    }

    function setVestingSchedule(
        address employee,
        uint256 cliffDuration,
        uint256 totalVestingDuration,
        uint256[] memory monthlyVesting
    ) public onlyOwner {
        require(cliffDuration <= totalVestingDuration, "Cliff duration must be less than or equal to total vesting duration");
        require(monthlyVesting.length == totalVestingDuration, "Invalid vesting schedule");

        vestingSchedules[employee].cliffDuration = cliffDuration;
        vestingSchedules[employee].totalVestingDuration = totalVestingDuration;
        vestingSchedules[employee].monthlyVesting = monthlyVesting;
        vestingSchedules[employee].startTime = block.timestamp;

        emit VestingScheduleSet(employee, cliffDuration, totalVestingDuration);
    }

    function exerciseOptions(uint256 amount) public onlyEmployee {
        require(amount > 0, "Amount must be greater than 0");

        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];

        require(vestingSchedule.vestedOptions >= vestingSchedule.exercisedOptions + amount, "Not enough vested options");

        vestingSchedule.exercisedOptions += amount;

        emit OptionsExercised(msg.sender, amount);
    }

    function getVestedOptions(address employee) public view returns (uint256) {
        VestingSchedule storage vestingSchedule = vestingSchedules[employee];

        if (block.timestamp < vestingSchedule.startTime + vestingSchedule.cliffDuration) {
            return 0;
        }

        if (block.timestamp >= vestingSchedule.startTime + vestingSchedule.totalVestingDuration) {
            return vestingSchedule.totalOptions;
        }

        uint256 passedMonths = (block.timestamp - vestingSchedule.startTime) / 30 days;

        uint256 vestedOptions = 0;
        for (uint256 i = 0; i <= passedMonths; i++) {
            vestedOptions += vestingSchedule.monthlyVesting[i];
        }

        return vestedOptions;
    }

    function getExercisedOptions(address employee) public view returns (uint256) {
        return vestingSchedules[employee].exercisedOptions;
    }

    function transferOptions(address to, uint256 amount) public onlyEmployee {
        require(amount > 0, "Amount must be greater than 0");

        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];

        require(vestingSchedule.vestedOptions >= vestingSchedule.exercisedOptions + amount, "Not enough vested options");

        vestingSchedule.exercisedOptions += amount;
        vestingSchedules[to].totalOptions += amount;

        emit OptionsExercised(msg.sender, amount);
    }
}