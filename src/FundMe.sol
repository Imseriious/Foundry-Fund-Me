// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address[] private s_funders; // []
    mapping(address funder => uint256 amount) private s_funderToAmount; // Private is more gas efficient. (If need to return, check getter function at the end of this file)

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Not enough founds"
        );
        s_funders.push(msg.sender);
        s_funderToAmount[msg.sender] = s_funderToAmount[msg.sender] + msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_funderToAmount[funder] = 0;
        }
        s_funders = new address[](0);

        //Transfer all the balance from this contract to the address that calls this function.
        payable(msg.sender).transfer(address(this).balance); //Can be done also with send, or call.
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _; //This tells the modifier to continue with what is inside of the function where it's used.
    }

    receive() external payable {
        fund(); //In case someone sends money directly to the contract by mistake, we also fund it.
    }

    fallback() external payable {
        fund();
    }

    // View / Pure functions (Getters)
    // We use this external, so we can return a variable, while keeping the variable private for gas efficiency.
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_funderToAmount[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
