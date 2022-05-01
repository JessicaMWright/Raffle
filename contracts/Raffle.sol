//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();
contract Raffle {

    enum RaffleState {
            Open,
            Calculating
        }

    RaffleState public s_raffleState;
    uint256 public immutable i_entranceFee;
    uint256 public immutable i_interval;
    address payable[] public s_players;
    uint256 public s_lastTimeStamp;
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;

    event RaffleEnter(address indexed player);

    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinatorV2
    ) {

        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    }

    function enterRaffle() external payable {
        //require(msg.value >= i_entranceFee, "not enough"); SAME AS BELOW less cost efficient 
        if(msg.value > i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        // open or calculating a winner
        if (s_raffleState != RaffleState.Open){
            revert Raffle__RaffleNotOpen();
        }
        // enter
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    // want this done automatically and real random winner

    // function below needs to be true after some time interval and the lottery to be open 
    // contract has eth 
    


    function checkUpkeep(bytes memory /*checkData*/) public view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool isOpen = RaffleState.Open == s_raffleState;
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance);
        return (upkeepNeeded,"   0x0");
    } 

    function performUpkeep(bytes calldata /*performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded();

        }
        s_raffleState = RaffleState.Calculating;
    }


    

}