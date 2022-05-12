//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


contract TimeLock {
    //declared erors
    error NotOwner();
    error AlreadyQueued(bytes32 txId);
    error TimestampNotInRange(uint blockTimestamp, uint timestamp);
    error NotQueued(bytes32 txId);
    error TimestampNotPassed( uint blocktimestamp, uint timestamp);
    error TimestampExpired(uint blocktimestamp,  uint expiresAt);
    error txFailed();
    

    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );

    event Cancel(bytes32 indexed txId);

    uint public constant MIN_DELAY = 10;
    uint public constant MAX_DELAY = 1000;
    uint public constant GRACE_PERIOD = 1000;

    address public owner;
    mapping(bytes32 => bool) public queued;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyOwner() {
        if (msg.sender != owner) {
        revert NotOwner();
        }
        _;
    }

    function getTxId(
         // contract to call
         address _target,
         // ether to send
         uint _value,
         // the function to call
         string calldata _func,
         // data to pass to function
         bytes calldata _data,
         // when function can be called
         uint _timestamp

    ) public pure returns (bytes32 txId) {
        return keccak256(
            abi.encode(
                _target, _value, _func, _data, _timestamp
            )
        );
    }
    
    
    function queue(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external onlyOwner {
        //tx id
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
        // check unique id
        if (queued[txId]) {
            revert AlreadyQueued(txId);
        }
        //check timestamp
        if (_timestamp < block.timestamp + MIN_DELAY || 
            _timestamp > block.timestamp + MAX_DELAY
        ){
            revert TimestampNotInRange(block.timestamp, _timestamp);
        }
        //queue tx
        queued[txId] = true;

        emit Queue(
            txId, _target, _value, _func, _data, _timestamp
        );
    }


    function execute(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
        //check tx queued
        if (!queued[txId]) {
            revert NotQueued(txId);
        }
        //check block.timestamp > _timestamp
        if (block.timestamp < _timestamp) {
            revert TimestampNotPassed(block.timestamp, _timestamp);
        }

        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TimestampExpired(block.timestamp, _timestamp + GRACE_PERIOD);
        }
        //delete tx
        queued[txId] = false;
        //execute tx
        bytes memory data;
        
        if (bytes (_func).length > 0) {
            data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data
        );
        } else {
            data = _data;
        }
        (bool ok, bytes memory res) =_target.call{value: _value}(data);
        if (!ok) {
            revert txFailed();
        }
        emit Execute(txId, _target, _value, _func, _data, _timestamp);
        return res;

    }

    function cancel(bytes32 _txId) external onlyOwner {
        if (!queued[_txId]) {
            revert NotQueued(_txId);
        }
    
        queued[_txId] = false;
        emit Cancel(_txId);
    }

}

