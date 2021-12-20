pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    mapping(address => uint256) public balances;
    uint256 public threshold = 1 ether;
    uint256 public deadline = block.timestamp + 2 days;
    bool public openForWithdraw = false;

    ExampleExternalContract public exampleExternalContract;

    event Stake(address, uint256);
    event Withdraw(address, uint256);

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    function stake() public payable notCompleted {
        require(!_deadlinePassed(), "Too late to stake.");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function withdraw(address withdrawAddr)
        public
        notCompleted
        returns (bool success)
    {
        require(openForWithdraw, "Withdrawals are not open.");
        require(balances[withdrawAddr] >= 0 && withdrawAddr == msg.sender);
        uint256 amount = balances[msg.sender];
        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
        return true;
    }

    function execute() public notCompleted returns (bool success) {
        require(_deadlinePassed(), "Too soon to execute.");
        require(!openForWithdraw, "Staking event failed.");
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
            return true;
        } else {
            openForWithdraw = true;
            return false;
        }
    }

    function timeLeft() public view returns (uint256) {
        return _deadlinePassed() ? 0 : deadline - block.timestamp;
    }

    function _deadlinePassed() private view returns (bool passed) {
        return block.timestamp >= deadline;
    }

    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Completed already.");
        _;
    }

    receive() external payable {
        stake();
    }
}
