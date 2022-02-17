// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

int constant VOTE_THRESHOLD = 50;

contract Incidents {
    enum STATUS { NONE, DISCUSSION, RESPONSE, INVALID, DUPLICATE, COMPLETED }

    address public owner;
    mapping(address => bool) public userRegistered;
    address[] public users;

    event CommentCreated(bytes32 ref);

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
        bytes32 incident_update;
        STATUS status_update;
    }

    struct Incident {
        uint created;
        address author;
        bytes32[] commentList;
        bytes32[] attachmentList;
        string[] attachmentNames;
        mapping(address => int) votes;
        STATUS status;
    }

    //only for returning data
    struct CommentPublic {
        bytes32 ref;
        bytes32 parent;
        uint created;
        address author;
        bytes32 content;
        Attachment[] attachments;
        Vote[] votes;
        bytes32 incident_update;
        STATUS status_update;
    }

    struct IncidentPublic{
        uint created;
        address author;
        CommentPublic[] comments;
        Attachment[] attachments;
        Vote[] votes;
        STATUS status;
    }

    struct Vote {
        address voter;
        int vote;
    }

    bytes32[] public incidentList;
    mapping(bytes32 => Incident) public incidents; // bytes32 key is also the hex-encoded sha2 IPFS hash
    mapping(bytes32 => Comment) public comments;

    //******* USERS ***********//
    function register(address user) onlyOwner external {
        require(!userRegistered[user]);
        users.push(user);
        userRegistered[user] = true;
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
            commentData[j] = comment2public(incidents[ref].commentList[j]);
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
        i.status = STATUS.DISCUSSION;
        incidentList.push(ref);
    }

    function voteIncident(bytes32 ref, int vote) onlyUser external {
        incidents[ref].votes[msg.sender] = vote;
    }

    function removeIncident(bytes32 incident, uint index) onlyUser external {
        delete incidents[incident];
        delete incidentList[index];
    }

    //******* COMMENTS *******//
    function getComment(bytes32 ref) onlyUser external view returns (CommentPublic memory){
        return comment2public(ref);
    }

    function addComment(bytes32 parent, bytes32 incident, bytes32 content,
            Attachment[] calldata attachments, bytes32 incident_update, STATUS status_update)
                onlyUser external {
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
        comments[ref].incident_update = incident_update;
        comments[ref].status_update = status_update;
        incidents[incident].commentList.push(ref);
        emit CommentCreated(ref);
    }

    function voteComment(bytes32 incident, bytes32 ref, int vote) onlyUser external {
        comments[ref].votes[msg.sender] = vote;
        int vote_tally = 0;
        for(uint j = 0; j<users.length; j++){
            if(comments[ref].votes[users[j]] > 0){
                vote_tally += comments[ref].votes[users[j]];
            }
        }
        if (vote_tally*100 > VOTE_THRESHOLD*int(users.length)) {
            if(comments[ref].status_update != STATUS.NONE) {
                incidents[incident].status = comments[ref].status_update;
                comments[ref].status_update = STATUS.NONE; //reset
            }
            if(comments[ref].incident_update != 0) {
                for(uint j = 0; j < incidentList.length; j++){
                    if(incidentList[j] == incident){
                        Incident storage k = incidents[incident];
                        Incident storage i = incidents[comments[ref].incident_update];
                        i.created = k.created;
                        i.author = k.author;
                        i.commentList = k.commentList;
                        i.attachmentList = k.attachmentList;
                        i.attachmentNames = k.attachmentNames;
                        i.status = k.status;
                        incidentList[j] = comments[ref].incident_update;
                        comments[ref].incident_update = 0;
                        //delete incidents[incident];
                        break;
                    }
                }
            }
        }
    }

    function removeComment(bytes32 incident, uint index) onlyUser external {
        bytes32 ref = keccak256(abi.encodePacked(incident,index));
        require(msg.sender == incidents[incident].author ||
                msg.sender == comments[ref].author);
        delete incidents[incident].commentList[index];
    }

    function comment2public(bytes32 ref) internal view returns (CommentPublic memory){
        Comment storage c = comments[ref];
        CommentPublic memory cp;
        cp.ref = ref;
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
        cp.incident_update = c.incident_update;
        cp.status_update = c.status_update;
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
