// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address TEST_USER = makeAddr("user"); // We use this foundry cheatcode to create a test user address. Easier to manage that test address.
    uint256 constant FUND_TEST_VALUE = 0.1 ether;
    uint256 constant TEST_USER_INITIAL_BALANCE = 1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(TEST_USER, TEST_USER_INITIAL_BALANCE); // Deal cheatcode to add some funds to the test user.
    }

    function testMinDollarIs5() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersion() public view {
        uint256 version = fundMe.getVersion();
        console.log("VERSION: ", version);
        assertEq(version, 4);
    }

    function testNotEnoughEth() public {
        vm.expectRevert(); //The next line should revert.
        fundMe.fund(); // Because we don't pass {value: xe18}, this will revert.
    }

    function testFundUpdatesFundedDataStructures() public {
        vm.prank(TEST_USER); // Prank means the next transaction will be executed by a specific address. TEST_USER we created above.
        fundMe.fund{value: FUND_TEST_VALUE}(); // Try to fund
        uint256 amountFunded = fundMe.getAddressToAmountFunded(TEST_USER); // Use of getter function
        assertEq(amountFunded, FUND_TEST_VALUE);
    }

    function testFunderToArrayOfFunders() public {
        vm.prank(TEST_USER); // Prank means the next transaction will be executed by a specific address. TEST_USER we created above.
        fundMe.fund{value: FUND_TEST_VALUE}(); // Try to fund
        address funder = fundMe.getFunder(0);
        assertEq(funder, TEST_USER);
    }
}
