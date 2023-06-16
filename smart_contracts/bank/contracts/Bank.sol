// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "hardhat/console.sol";


contract Bank{

    bool full = false;
    uint quantity = 0;
    uint limit = 100;
    address owner = msg.sender;


    struct result{
        bool success;
        uint current_quantity;
        uint remaining_space;
        uint qty;
    }




    function is_full() public view returns(bool){
        return full;
    }

    function get_quantity() public view returns(uint){
        return quantity;
    }

    function get_limit() public view returns(uint){
        return limit;
    }

    function get_status() public view returns(uint, uint, uint){
        return (quantity, limit, limit-quantity);
    }

    function get_owner() public view returns(address){
        return (owner);
    }


    function add(uint qty) public returns(bool, uint, uint, uint){
        //require(!full);
        if(quantity + qty  > limit){
            return (false, quantity, limit-quantity, qty);
        }
        else{
            quantity += qty;
            if(quantity == limit) full = true;
            return (true, quantity, limit-quantity, qty);
        }
    }


    function remove(uint qty) public returns (bool, uint, uint, uint){
        if(qty > quantity){
            return (false, quantity, limit-quantity, qty);
        }
        else{
            quantity -= qty;
            if(full == true) full = false;
            return (true, quantity, quantity, qty);
        }
    }

    function get_data() public pure returns (string memory){
        return string(msg.data);
    }

    // function send_money(address payable _to) public payable returns(address,address){
    function send_money(address payable _to) public payable returns(bool){

        // receiver.transfer(1);
        // require(owner.balance>msg.value,"not enough ethers");
        if(msg.sender == owner){
            // bool res = _to.send(msg.value);
            _to.transfer(msg.value);   
            // return (msg.sender,_to);

        }
        return (false);
        // else{
        //     return address(2);
        // }
        // bool sent = _to.send(qty);
        // require(sent, "Failed to send Ether");
        // return sent;
    }
}