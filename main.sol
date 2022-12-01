// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }
}

contract Oddit {

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                     MAPPINGS, VARIABLES AND CONSTRUCTOR                      //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    using SafeMath for uint;

    struct Match {
        uint id;
        string name;
        uint odds1;
        uint odds2;
        uint start;
        bool isEnded;
        uint winner; // 1 or 2
        address referee;
    }

    struct Bet {
        uint id;
        uint choice;
        uint amount;
        uint odds;
    }

    struct Order {
        uint id;
        uint choice;
        uint totalAmount;
        uint filledAmount;
        uint odds;
    }

    mapping (address => bool) public isManager;
    mapping (address => bool) public isBlacklisted;
    // ID => Match
    mapping (uint => Match) MATCHES;
    // Owner => Match ID => Bet
    mapping (address => mapping (uint => Bet)) BETS;
    // Owner => Match ID => Order
    mapping (address => mapping (uint => Order)) ORDERS;

    address owner;
    address defaultReferee;
    address USDT = address(this);
    address USDC = address(this);

    uint nextMatchId;
    uint nextBetId;

    constructor() {
        owner = msg.sender;
        switchManager(msg.sender);
        nextMatchId = 1;
        nextBetId = 1;
        defaultReferee = msg.sender;
    }
    
    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                              PRIVATE FUNCTIONS                               //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function switchManager(address _user) public onlyOwner {
        isManager[_user] = !isManager[_user];
    }

    function createMatch(string memory _name, uint _odds1, uint _odds2, uint _start) public onlyManager {
        MATCHES[nextMatchId].id = nextMatchId;
        MATCHES[nextMatchId].name = _name;
        MATCHES[nextMatchId].odds1 = _odds1;
        MATCHES[nextMatchId].odds2 = _odds2;
        MATCHES[nextMatchId].start = _start;
        nextMatchId = nextMatchId.add(1);
    }

    function endMatch(uint _id, uint _winner) public onlyManager {
        MATCHES[_id].isEnded = true;
        MATCHES[_id].winner = _winner;
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                               VIEW FUNCTIONS                                 //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function getNextMatchId() public view returns (uint) {
        return nextMatchId;
    }

    function getMatch(uint _id) public view returns (Match memory) {
        return MATCHES[_id];
    }

    function getTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                             INTERNAL FUNCTIONS                               //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////



    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                              PUBLIC FUNCTIONS                                //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function createBet(uint _id, uint _side, uint _amount, uint _odds) public matchOpen(_id) matchExists(_id) sideValid(_side) {
        
    }

    function cancelBet(uint _id) public matchOpen(_id) matchExists(_id) {
        
    }

    function createMarketBet(uint _id, uint _side, uint _amount) public matchOpen(_id) matchExists(_id) sideValid(_side) {
        
    }

    function claimBet(uint _id) public matchExists(_id) matchEnded(_id) {
        
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                                  MODIFIERS                                   //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    modifier matchOpen(uint _id) {
        require(block.timestamp < MATCHES[_id].start, "Match already started");
        _;
    }

    modifier matchEnded(uint _id) {
        require(MATCHES[_id].isEnded == true, "Match already started");
        _;
    }

    modifier matchExists(uint _id) {
        require(_id < nextMatchId, "Match doesn't exist");
        _;
    }

    modifier sideValid(uint _side) {
        require(_side == 1 || _side == 2, "Side not valid");
        _;
    }

    modifier onlyManager() {
        require(isManager[msg.sender] == true, "Not manager");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}
