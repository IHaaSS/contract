// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;


contract Incidents {
    address public owner;

    constructor () {
        owner = msg.sender;
    }

    struct Attachment {
        string name;
        bytes32 content;
    }

    struct Comment {
        bytes32 parent;
        uint created;
        address author;
        bytes32 content;
        bytes32[] attachmentList; //keeps track of attachment keys
        address[] votedUp;
        address[] votedDown;
    }

    struct Incident {
        uint created;
        address author;
        bytes32[] commentList;
        bytes32[] attachmentList;
        address[] votedUp;
        address[] votedDown;
    }

    bytes32[] public incidentList;
    mapping(bytes32 => Incident) public incidents; // bytes32 key is also the hex-encoded sha2 IPFS hash
    mapping(bytes32 => Comment) public comments;
    mapping(bytes32 => string) public attachmentNames;

    //******* INCIDENTS *******//

    function getIncidents() external view returns (bytes32[] memory){
        return incidentList;
    }

    function getIncident(bytes32 ref) external view returns (bytes32, uint, address, bytes32[] memory, bytes32[] memory,
            address[] memory, address[] memory){
        return (ref, incidents[ref].created, incidents[ref].author,
                incidents[ref].commentList, incidents[ref].attachmentList,
                incidents[ref].votedUp, incidents[ref].votedDown);
    }

    function addIncident(bytes32 ref, Attachment[] calldata attachments) external {
        require(incidents[ref].created == 0); //duplicate check
        Incident memory i;
        i.created = block.timestamp;
        i.author = msg.sender;
        incidents[ref] = i;
        for(uint j=0; j<attachments.length; j++){
            incidents[ref].attachmentList.push(attachments[j].content);
            attachmentNames[attachments[j].content] = attachments[j].name;
        }
        incidentList.push(ref);
    }

    function voteIncident(bytes32 ref, bool up) external {
        if(up) incidents[ref].votedUp.push(msg.sender);
        else incidents[ref].votedDown.push(msg.sender);
    }

    function removeIncident(bytes32 incident, uint index) external {
        require(msg.sender == incidents[incident].author);
        delete incidents[incident];
        delete incidentList[index];
    }

    //******* COMMENTS *******//

    function getComment(bytes32 ref) external view returns (
            bytes32, uint, address, bytes32, bytes32[] memory, address[] memory, address[] memory){
        return (comments[ref].parent, comments[ref].created, comments[ref].author,
                comments[ref].content,
                comments[ref].attachmentList,
                comments[ref].votedUp, comments[ref].votedDown);
    }

    function addComment(bytes32 parent, bytes32 incident, bytes32 content,
            Attachment[] calldata attachments) external {
        uint index = incidents[incident].commentList.length;
        bytes32 ref = keccak256(abi.encodePacked(incident,index));
        comments[ref].created = block.timestamp;
        comments[ref].author = msg.sender;
        comments[ref].parent = parent;
        comments[ref].content = content;
        for(uint i=0; i<attachments.length; i++){
            comments[ref].attachmentList.push(attachments[i].content);
            attachmentNames[attachments[i].content] = attachments[i].name;
        }
        incidents[incident].commentList.push(ref);
    }

    function voteComment(bytes32 ref, bool up) external {
        if(up) comments[ref].votedUp.push(msg.sender);
        else comments[ref].votedDown.push(msg.sender);
    }

    function removeComment(bytes32 incident, uint index) external {
        delete incidents[incident].commentList[index];
    }
}
