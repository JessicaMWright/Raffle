//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract HotelRoom{

    enum Statuses {
        Vacant,
        Occupied
    }
    Statuses public currentStatus;

    event Occupy(address _occupant, uint _value);

    address payable owner;

    constructor() {
        owner == msg.sender;
        currentStatus = Statuses.Vacant;
    }

    modifier onlyWhenVacant {
        require(currentStatus == Statuses.Vacant, "currently occupied");
        _;
    }
    modifier cost(uint _amount) {
        require(msg.value >= _amount, "not enough");
        _;
    }
    function book()public payable onlyWhenVacant cost(2 ether) {
        currentStatus = Statuses.Occupied;

        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        require(sent);

        emit Occupy(msg.sender, msg.value);
    }
}