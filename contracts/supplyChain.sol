//SPDX-License-Identifier: MIT
// basic supply chain contract
pragma solidity >=0.7.0 <0.9.0;

contract supplyChain {

    address payable owner;
    struct item {
        uint price;
        string descripton;
        address buyer;
    }
    mapping(uint => item) public items;
    uint private counter = 0;

    modifier onlyOwner{
        require(msg.sender == owner, "not owner");
        _;
    }
    modifier PaidEnough(uint _price) {
        require(msg.value > _price);
        _;
    }

    constructor() {
        owner = payable(msg.sender);

    }

    function add(uint _price, string memory _description) public onlyOwner {
        items[counter] = item(_price, _description, address(0));
        counter ++;

    }
    function buy(uint _id) public payable PaidEnough(msg.value) {
        owner.transfer(msg.value);
        items[_id].buyer = msg.sender;


    }


}