// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address[] public funders; // []
    mapping(address funder => uint256 amount) public funderToAmount;

    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(
            msg.value.gerConversionRate() >= MINIMUM_USD,
            "Not enough founds"
        );
        funders.push(msg.sender);
        funderToAmount[msg.sender] = funderToAmount[msg.sender] + msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            funderToAmount[funder] = 0;
        }
        funders = new address[](0);

        //Transfer all the balance from this contract to the address that calls this function.
        payable(msg.sender).transfer(address(this).balance); //Can be done also with send, or call.
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Sender is not owner");
        _; //This tells the modifier to continue with what is inside of the function where it's used.
    }

    receive() external payable {
        fund(); //In case someone sends money directly to the contract by mistake, we also fund it.
    }

    fallback() external payable {
        fund();
    }
}
