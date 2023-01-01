// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./openzeppelin/SafeMath.sol";
import "./openzeppelin/IERC20.sol";

interface IMATCH {
    function createOrderLeft(address _sender, uint _odds, uint _amount) external;
    function createOrderRight(address _sender, uint _odds, uint _amount) external;
}

contract OdditMaster {

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                     MAPPINGS, VARIABLES AND CONSTRUCTOR                      //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    using SafeMath for uint;

    address public owner;
    address public treasury;

    // Divide fees by 1000
    uint public fees;

    uint public nextOrderId;
    uint public nextBetId;
    uint public nextMatchId;

    struct MasterOrder {
        uint id;
        address game;
    }

    struct MasterBet {
        uint id;
        address game;
    }

    struct User {
        address addy;
        string name;
        IERC20 currency;
        MasterOrder[] orders;
        MasterBet[] bets;
    }

    mapping (address => bool) public isManager;
    mapping (address => bool) public isMatch;

    mapping (uint => IERC20) public currencyContracts;
    mapping (uint => string) public currencyNames;
    mapping (uint => bool) public currencyIsActive;

    // Infos about the users on the app
    mapping (address => User) public users;

    constructor() {
        owner = msg.sender;
        treasury = address(this);
        addManager(msg.sender);
    }

    event CallOrder(uint matchId, uint side, uint amount, uint odds);
    
    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                              PRIVATE FUNCTIONS                               //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////
    
    function setOwner(address _user) public onlyOwner {
        owner = _user;
    }

    function addManager(address _user) public onlyOwner {
        isManager[_user] = true;
    }

    function removeManager(address _user) public onlyOwner {
        isManager[_user] = false;
    }

    function appendOrder(address _user, uint _id, address _match) public {
        MasterOrder memory order;
        order.id = _id;
        order.game = _match;

        users[_user].orders.push(order);
    }

    function appendBet(address _user, uint _id, address _match) public {
        MasterBet memory bet;
        bet.id = _id;
        bet.game = _match;

        users[_user].bets.push(bet);
    }

    function addCurrency(uint _id, string memory _name, address _addy) public onlyManager {
        currencyNames[_id] = _name;
        currencyIsActive[_id] = true;
        currencyContracts[_id] = IERC20(_addy);
    }

    function addMatch(address _address) public onlyManager {
        isMatch[_address] = true;
    }

    function enableCurrency(uint _currencyId) public onlyManager {
        currencyIsActive[_currencyId] = true;
    }

    function disableCurrency(uint _currencyId) public onlyManager {
        currencyIsActive[_currencyId] = false;
    }

    function setFees(uint _value) public onlyManager {
        fees = _value;
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                               VIEW FUNCTIONS                                 //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function getTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    function getOrders(address _user) public view returns (MasterOrder[] memory) {
        return users[_user].orders;
    }

    function getBets(address _user) public view returns (MasterBet[] memory) {
        return users[_user].bets;
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

    function callOrder(address _match, uint _side, uint _odds, uint _amount) public {
        require(_odds >= 101 && _odds <= 10100, "Wrong odds");
        require(_side == 1 || _side == 2, "Wrong side");
        require(isMatch[_match] == true, "Match doesn't exist");

        IMATCH odditMatch = IMATCH(_match);
        // Send _amount stable tokens to this address
        IERC20 stable = users[msg.sender].currency;
        stable.transferFrom(msg.sender, treasury, _amount);


        if (_side == 1) {
            odditMatch.createOrderLeft(msg.sender, _odds, _amount);
        }

        if (_side == 2) {
            odditMatch.createOrderRight(msg.sender, _odds, _amount);
        }
    }
    
    function setCurrency(address _currency) public {
        users[msg.sender].currency = IERC20(_currency);
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                                  MODIFIERS                                   //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyManager() {
        require(isManager[msg.sender] == true, "Not manager");
        _;
    }
}