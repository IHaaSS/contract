pragma solidity ^0.8.3;


contract Incidents {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    struct Comment {
        uint created;
        address author;
        bytes32 content;
    }

    struct Discussion {
        uint created;
        Comment[] comments;
    }

    struct Incident {
        uint created;
        address author;
        Discussion discussion;
    }

    mapping(bytes32 => Incident) public incidents; // bytes32 key is also the hex-encoded sha2 IPFS hash

}