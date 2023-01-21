// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./openzeppelin/SafeMath.sol";
import "./openzeppelin/IERC20.sol";

interface IMASTER {
    function appendOrder(address _user, uint _id, address _match) external;
    function appendBet(address _user, uint _id, address _match) external;
}

contract OdditMatch {

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                     MAPPINGS, VARIABLES AND CONSTRUCTOR                      //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    using SafeMath for uint;

    IMASTER public odditMaster;

    address public owner;
    address public master;

    uint public expirationCooldown = 1000;
    uint public nextOrderId;
    uint public nextBetId;

    string public matchName;
    uint public matchStart;
    uint public matchWinner;
    uint public matchExpiration;
    bool public isEnded;

    struct Order {
        uint id;
        address owner;
        uint side;
        uint odds;
        uint totalAmount;
        uint remainingAmount;
    }

    struct Bet {
        uint id;
        address owner;
        uint side; // 0 if the bet has been claimed
        uint odds;
        uint amount;
    }

    struct Step {
        uint256 lowerOdds;
        uint256 higherOdds;
        uint256 amount;
    }

    mapping (address => bool) public isManager;

    // System mappings
    mapping (uint => Order) public ORDERS;
    mapping (uint => Bet) public BETS;

    // Orderbook for team 1
    mapping (uint => Step) public leftSteps;
    mapping (uint => mapping (uint => uint)) public leftOrdersInStep;
    mapping (uint => uint) public leftOrdersInStepC;
    uint public minLeftOdds;

    // Orderbook for team 2
    mapping (uint => Step) public rightSteps;
    mapping(uint => mapping (uint => uint)) public rightOrdersInStep;
    mapping(uint => uint) public rightOrdersInStepC;
    uint public minRightOdds;

    constructor(address _master, string memory _matchName, uint _matchStart) {
        owner = msg.sender;
        master = _master;
        matchName = _matchName;
        matchStart = _matchStart;
        matchExpiration = _matchStart + expirationCooldown;

        odditMaster = IMASTER(master);
    }

    event OrderCreated(uint side, uint amount, uint odds);
    event OrderDeleted(uint orderId);
    event OrderFilled(uint orderId, uint _amount);
    
    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                              PRIVATE FUNCTIONS                               //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function endMatch(uint _winner) public onlyMaster {
        require(isEnded == false, "Match already ended");

        isEnded = true;
        matchWinner = _winner;
    }
    
    function setOwner(address _user) public onlyOwner {
        owner = _user;
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

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                             INTERNAL FUNCTIONS                               //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function oppositeOdds(uint _odds) public pure returns (uint) {
        return _odds.mul(100).div(_odds.sub(100));
    }

    function oppositeAmount(uint _odds, uint _amount) public pure returns (uint) {
        return _amount.mul(100).div(oppositeOdds(_odds).sub(100));
    }

    function makeOrder(address _owner, uint _side, uint _odds, uint _amount) public {
        ORDERS[nextOrderId].id = nextOrderId;
        ORDERS[nextOrderId].owner = _owner;
        ORDERS[nextOrderId].side = _side;
        ORDERS[nextOrderId].odds = _odds;
        ORDERS[nextOrderId].totalAmount = _amount;
        ORDERS[nextOrderId].remainingAmount = _amount;

        odditMaster.appendOrder(_owner, nextOrderId, address(this));

        nextOrderId = nextOrderId += 1;
    }

    function makeBet(address _owner, uint _side, uint _odds, uint _amount) public { // SET TO INTERNAL
        BETS[nextBetId].id = nextBetId;
        BETS[nextBetId].owner = _owner;
        BETS[nextBetId].side = _side;
        BETS[nextBetId].odds = _odds;
        BETS[nextBetId].amount = _amount;
        
        odditMaster.appendBet(_owner, nextBetId, address(this));

        nextBetId = nextBetId + 1;
    }

    function addToLeft(address _owner, uint _odds, uint _amount) public {
        leftOrdersInStep[_odds][leftOrdersInStepC[_odds]] = nextOrderId;
        leftOrdersInStepC[_odds] += 1;
        leftSteps[_odds].amount += _amount;

        // Add order to the mapping
        makeOrder(_owner, 2, _odds, _amount);

        // If first order, update minimum odds
        if (minLeftOdds == 0) {
            minLeftOdds = _odds;
            return;
        }

        // If order is the closest to market
        if (_odds < minLeftOdds) {
            leftSteps[minLeftOdds].lowerOdds = _odds;
            leftSteps[_odds].higherOdds = minLeftOdds;
            minLeftOdds = _odds;
            return;
        }

        if (_odds == minLeftOdds) {
            return;
        }

        // If order is between 2 steps, do this
        uint leftOddsPointer = minLeftOdds;
        
        while (_odds >= leftOddsPointer && leftSteps[leftOddsPointer].higherOdds != 0) {
            leftOddsPointer = leftSteps[leftOddsPointer].higherOdds;
        }

        if (leftOddsPointer < _odds) {
            leftSteps[_odds].lowerOdds = leftOddsPointer;
            leftSteps[leftOddsPointer].higherOdds = _odds;
        }

        if (leftOddsPointer > _odds && _odds > leftSteps[leftOddsPointer].lowerOdds) {
            leftSteps[_odds].lowerOdds = leftSteps[leftOddsPointer].lowerOdds;
            leftSteps[_odds].higherOdds = leftOddsPointer;

            leftSteps[leftSteps[leftOddsPointer].lowerOdds].higherOdds = _odds;
            leftSteps[leftOddsPointer].lowerOdds = _odds;
        }
    }

    function addToRight(address _owner, uint _odds, uint _amount) public {
        rightOrdersInStep[_odds][rightOrdersInStepC[_odds]] = nextOrderId;
        rightOrdersInStepC[_odds] += 1;
        rightSteps[_odds].amount += _amount;

        // Add order to the mapping
        makeOrder(_owner, 2, _odds, _amount);

        // If first order, update minimum odds
        if (minRightOdds == 0) {
            minRightOdds = _odds;
            return;
        }

        // If order is the closest to market
        if (_odds < minRightOdds) {
            rightSteps[minRightOdds].lowerOdds = _odds;
            rightSteps[_odds].higherOdds = minRightOdds;
            minRightOdds = _odds;

            return;
        }

        if (_odds == minRightOdds) {
            return;
        }

        // If order is between 2 steps, do this
        uint rightOddsPointer = minRightOdds;
        
        while (_odds >= rightOddsPointer && rightSteps[rightOddsPointer].higherOdds != 0) {
            rightOddsPointer = rightSteps[rightOddsPointer].higherOdds;
        }

        if (rightOddsPointer < _odds) {
            rightSteps[_odds].lowerOdds = rightOddsPointer;
            rightSteps[rightOddsPointer].higherOdds = _odds;
        }

        if (rightOddsPointer > _odds && _odds > rightSteps[rightOddsPointer].lowerOdds) {
            rightSteps[_odds].lowerOdds = rightSteps[rightOddsPointer].lowerOdds;
            rightSteps[_odds].higherOdds = rightOddsPointer;

            rightSteps[rightSteps[rightOddsPointer].lowerOdds].higherOdds = _odds;
            rightSteps[rightOddsPointer].lowerOdds = _odds;
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                              PUBLIC FUNCTIONS                                //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function createOrderLeft(address _sender, uint _odds, uint _amount) public {
        
        uint remaining = _amount;
        uint newOdds = oppositeOdds(_odds);

        uint rightOddsPointer = minRightOdds;

        // If newOdds is higher than minRightOdds, fill fillable orders with odds lower than newOdds
        if (newOdds >= minRightOdds && minRightOdds > 0) {

            // Loop through steps
            while (remaining > 0 && rightOddsPointer <= newOdds && rightOddsPointer != 0) {

                uint i = 0;

                // Loop through orders in step
                while (remaining > 0 && i < rightOrdersInStepC[rightOddsPointer]) {

                    Order storage currOrder = ORDERS[rightOrdersInStep[rightOddsPointer][i]];

                    uint betOdds = oppositeOdds(currOrder.odds);
                    uint betAmount = oppositeAmount(currOrder.odds, currOrder.remainingAmount);

                    // If the current order is empty, go to next order
                    if (currOrder.remainingAmount == 0) {
                        i += 1;
                        continue;
                    }

                    // If the current order is not enough, completely fill it
                    if (oppositeAmount(oppositeOdds(currOrder.odds), remaining) >= currOrder.remainingAmount) {
                        makeBet(_sender, 1, betOdds, betAmount);
                        makeBet(currOrder.owner, 2, currOrder.odds, currOrder.remainingAmount);

                        currOrder.remainingAmount = 0;
                        rightSteps[rightOddsPointer].amount = 0;
                        remaining = remaining.sub(betAmount);

                        minRightOdds = rightSteps[rightOddsPointer].higherOdds;
                    }

                    // If the current order is enough, partially fill it
                    else{
                        makeBet(_sender, 1, betOdds, remaining);
                        makeBet(currOrder.owner, 2, currOrder.odds, oppositeAmount(oppositeOdds(currOrder.odds), remaining));

                        rightSteps[rightOddsPointer].amount = rightSteps[rightOddsPointer].amount - oppositeAmount(oppositeOdds(currOrder.odds), remaining);
                        currOrder.remainingAmount = currOrder.remainingAmount - oppositeAmount(oppositeOdds(currOrder.odds), remaining);
                        remaining = 0;
                    }

                    i += 1;
                }
            
            rightOddsPointer = rightSteps[rightOddsPointer].higherOdds;
            }
        }

        // Create order if remaining is higher than 0
        if(remaining > 0) {
            addToLeft(_sender, _odds, remaining);
        }
    }

    function createOrderRight(address _sender, uint _odds, uint _amount) public {

        uint remaining = _amount;
        uint newOdds = oppositeOdds(_odds);

        uint leftOddsPointer = minLeftOdds;

        // If newOdds is higher than minLeftOdds, fill fillable orders with odds lower than newOdds
        if (newOdds >= minLeftOdds && minLeftOdds > 0) {

            // Loop through steps
            while (remaining > 0 && leftOddsPointer <= newOdds && leftOddsPointer != 0) {

                uint i = 0;

                // Loop through orders in step
                while (remaining > 0 && i < leftOrdersInStepC[leftOddsPointer]) {

                    Order storage currOrder = ORDERS[leftOrdersInStep[leftOddsPointer][i]];

                    uint betOdds = oppositeOdds(currOrder.odds);
                    uint betAmount = oppositeAmount(currOrder.odds, currOrder.remainingAmount);

                    // If the current order is empty, go to next order
                    if (currOrder.remainingAmount == 0) {
                        i += 1;
                        continue;
                    }

                    // If the current order is not enough, completely fill it
                    if (oppositeAmount(oppositeOdds(currOrder.odds), remaining) >= currOrder.remainingAmount) {
                        makeBet(_sender, 2, betOdds, betAmount);
                        makeBet(currOrder.owner, 1, currOrder.odds, currOrder.remainingAmount);

                        currOrder.remainingAmount = 0;
                        leftSteps[leftOddsPointer].amount;
                        remaining = remaining.sub(betAmount);

                        minLeftOdds = leftSteps[leftOddsPointer].higherOdds;
                    }

                    // If the current order is enough, partially fill it
                    else {
                        makeBet(_sender, 2, betOdds, remaining);
                        makeBet(currOrder.owner, 1, currOrder.odds, oppositeAmount(oppositeOdds(currOrder.odds), remaining));

                        leftSteps[leftOddsPointer].amount = leftSteps[leftOddsPointer].amount - oppositeAmount(oppositeOdds(currOrder.odds), remaining);
                        currOrder.remainingAmount = currOrder.remainingAmount - oppositeAmount(oppositeOdds(currOrder.odds), remaining);
                        remaining = 0;
                    }

                    i += 1;
                }
            
            leftOddsPointer = leftSteps[leftOddsPointer].higherOdds;
            }
        }

        // Create order if remaining is higher than 0
        if(remaining > 0) {
            addToRight(_sender, _odds, remaining);
        }
    }

    function deleteOrder(uint _orderId) public {
        require(msg.sender == ORDERS[_orderId].owner, "Not authorized");

        uint odds = ORDERS[_orderId].odds;

        if (ORDERS[_orderId].side == 1) {
            leftSteps[odds].amount -= ORDERS[_orderId].remainingAmount;

            if (odds < minLeftOdds) {
                minLeftOdds = leftSteps[odds].higherOdds;
            }
        }

        if (ORDERS[_orderId].side == 2) {
            rightSteps[odds].amount -= ORDERS[_orderId].remainingAmount;

            if (odds < minRightOdds) {
                minRightOdds = rightSteps[odds].higherOdds;
            }
        }

        ORDERS[_orderId].remainingAmount = 0;
    }

    function claimBet(uint _betId) public {

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

    modifier onlyMaster() {
        require(msg.sender == master, "Not master");
        _;
    }
}