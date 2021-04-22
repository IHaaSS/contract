// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;


contract Incidents {
    address public owner;

    constructor () {
        owner = msg.sender;
    }

    struct Attachment {
        string name;
        bytes32 ipfsHash;
    }

    struct Comment {
        uint created;
        address author;
        bytes32 content;
        bytes32[] attachmentList; //keeps track of attachment keys
        mapping(bytes32 => string) attachments;
    }

    struct Incident {
        uint created;
        address author;
        bytes32[] commentList;
    }

    bytes32[] public incidentList;
    mapping(bytes32 => Incident) public incidents; // bytes32 key is also the hex-encoded sha2 IPFS hash
    mapping(bytes32 => Comment) public comments;

    function getIncidents() external view returns (bytes32[] memory){
        return incidentList;
    }


    function addIncident(bytes32 ipfsHash) external {
        Incident memory i;
        i.created = block.timestamp;
        i.author = msg.sender;
        incidents[ipfsHash] = i;
        incidentList.push(ipfsHash);
    }

    function addComment(bytes32 incident, bytes32 content, Attachment[] calldata attachments) external {
        bytes32 ref = keccak256(abi.encodePacked(incident,content));
        comments[ref].created = block.timestamp;
        comments[ref].author = msg.sender;
        for(uint i=0; i<attachments.length; i++){
            comments[ref].attachmentList.push(attachments[i].ipfsHash);
            comments[ref].attachments[attachments[i].ipfsHash] = attachments[i].name;
        }
        incidents[incident].commentList.push(ref);
    }

    function removeComment(bytes32 incident, uint index) external {
        delete incidents[incident].commentList[index];
    }
}