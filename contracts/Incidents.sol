// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;


contract Incidents {
    address public owner;
    mapping(address => bool) public userRegistered;
    address[] public users;

    constructor () {
        owner = msg.sender;
        users.push(msg.sender);
        userRegistered[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyUser() {
        require(userRegistered[msg.sender]);
        _;
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
        string[] attachmentNames;
        mapping(address => int) votes;
    }

    struct Incident {
        uint created;
        address author;
        bytes32[] commentList;
        bytes32[] attachmentList;
        string[] attachmentNames;
        mapping(address => int) votes;
    }


    //only for returning data
    struct CommentPublic {
        bytes32 parent;
        uint created;
        address author;
        bytes32 content;
        Attachment[] attachments;
        Vote[] votes;
    }

    struct IncidentPublic{
        uint created;
        address author;
        CommentPublic[] comments;
        Attachment[] attachments;
        Vote[] votes;
    }

    struct Vote {
        address voter;
        int vote;
    }

    bytes32[] public incidentList;
    mapping(bytes32 => Incident) public incidents; // bytes32 key is also the hex-encoded sha2 IPFS hash
    mapping(bytes32 => Comment) public comments;

    //******* USERS ***********//
    function register() onlyOwner external {
        require(!userRegistered[msg.sender]);
        users.push(msg.sender);
        userRegistered[msg.sender] = true;
    }


    //******* INCIDENTS *******//
    function getIncidents() onlyUser external view returns (bytes32[] memory){
        return incidentList;
    }

    function getIncident(bytes32 ref) onlyUser external view returns(
            IncidentPublic memory){
        IncidentPublic memory i;
        CommentPublic[] memory commentData = new CommentPublic[](incidents[ref].commentList.length);
        for(uint j=0; j<incidents[ref].commentList.length; j++){
            commentData[j] = comment2public(comments[incidents[ref].commentList[j]]);
        }
        Attachment[] memory attachmentData = getIncidentAttachments(incidents[ref]);
        Vote[] memory voteData = new Vote[](users.length);
        for(uint j = 0; j<users.length; j++){
            voteData[j].voter = users[j];
            voteData[j].vote = incidents[ref].votes[users[j]];
        }
        i.created = incidents[ref].created;
        i.author = incidents[ref].author;
        i.comments = commentData;
        i.attachments = attachmentData;
        i.votes = voteData;
        return i;
    }

    function addIncident(bytes32 ref, Attachment[] calldata attachments) onlyUser external {
        require(incidents[ref].created == 0); //duplicate check
        Incident storage i = incidents[ref];
        i.created = block.timestamp;
        i.author = msg.sender;
        for(uint j=0; j<attachments.length; j++){
            incidents[ref].attachmentList.push(attachments[j].content);
            incidents[ref].attachmentNames.push(attachments[j].name);
        }
        incidentList.push(ref);
    }

    function voteIncident(bytes32 ref, int vote) onlyUser external {
        incidents[ref].votes[msg.sender] = vote;
    }

    function removeIncident(bytes32 incident, uint index) onlyUser external {
        require(msg.sender == incidents[incident].author);
        delete incidents[incident];
        delete incidentList[index];
    }

    //******* COMMENTS *******//
    function getComment(bytes32 ref) onlyUser external view returns (CommentPublic memory){
        return comment2public(comments[ref]);
    }

    function addComment(bytes32 parent, bytes32 incident, bytes32 content,
            Attachment[] calldata attachments) onlyUser external returns (bytes32) {
        uint index = incidents[incident].commentList.length;
        bytes32 ref = keccak256(abi.encodePacked(incident,index));
        comments[ref].created = block.timestamp;
        comments[ref].author = msg.sender;
        comments[ref].parent = parent;
        comments[ref].content = content;
        for(uint i=0; i<attachments.length; i++){
            comments[ref].attachmentList.push(attachments[i].content);
            comments[ref].attachmentNames.push(attachments[i].name);
        }
        incidents[incident].commentList.push(ref);
        return ref;
    }

    function voteComment(bytes32 ref, int vote) onlyUser external {
        comments[ref].votes[msg.sender] = vote;
    }

    function removeComment(bytes32 incident, uint index) onlyUser external {
        bytes32 ref = keccak256(abi.encodePacked(incident,index));
        require(msg.sender == incidents[incident].author ||
                msg.sender == comments[ref].author);
        delete incidents[incident].commentList[index];
    }

    function comment2public(Comment storage c) internal view returns (CommentPublic memory){
        CommentPublic memory cp;
        cp.parent = c.parent;
        cp.created = c.created;
        cp.author = c.author;
        cp.content = c.content;
        cp.attachments = getCommentAttachments(c);
        Vote[] memory voteData = new Vote[](users.length);
        for(uint j = 0; j<users.length; j++){
            voteData[j].voter = users[j];
            voteData[j].vote = c.votes[users[j]];
        }
        cp.votes = voteData;
        return cp;
    }

    function getIncidentAttachments(Incident storage i) internal view returns (Attachment[] memory){
        Attachment[] memory attachments = new Attachment[](i.attachmentList.length);
        for(uint j = 0; j< i.attachmentList.length; j++){
            attachments[j].content = i.attachmentList[j];
            attachments[j].name = i.attachmentNames[j];
        }
        return attachments;
    }

    function getCommentAttachments(Comment storage c) internal view returns (Attachment[] memory){
        Attachment[] memory attachments = new Attachment[](c.attachmentList.length);
        for(uint j = 0; j< c.attachmentList.length; j++){
            attachments[j].content = c.attachmentList[j];
            attachments[j].name = c.attachmentNames[j];
        }
        return attachments;
    }
}
