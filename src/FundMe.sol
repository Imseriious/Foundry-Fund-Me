// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address[] public funders; // []
    mapping(address funder => uint256 amount) public funderToAmount;

    address public immutable i_owner;
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
}
