// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;


import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/test_contract.sol";

contract TestBank{

    Bank p = Bank(DeployedAddresses.Bank());
    bool success;
    uint current_quantity;
    uint remaining_space;
    uint qty;


    function testInitialization() public {
        Assert.equal(p.is_full(), false, "full is not false");
        Assert.equal(p.get_quantity(), 0, "initial quantity is not 0");
        Assert.equal(p.get_limit(), 100, "initial limit is not 100");
    }

    function testAdd() public{
        (success, current_quantity, remaining_space, qty) = p.add(15);
        Assert.equal(success, true, "add1 didn't succeded");
        Assert.equal(current_quantity, 15, "add1 wrong quantity");
        Assert.equal(remaining_space, 85, "add1 wrong remaining space");
        Assert.equal(qty, 15, "add1 wrong qty");

        (success, current_quantity, remaining_space, qty) = p.add(90);
        Assert.equal(success, false, "add2 wrongly succeded");
        Assert.equal(current_quantity, 15, "add2 wrong quantity");
        Assert.equal(remaining_space, 85, "add2 wrong remaining space");
        Assert.equal(qty, 15, "add2 wrong qty");
    }

    function testRemove() public{
        (success, current_quantity, remaining_space, qty) = p.remove(10);
        Assert.equal(success, true, "rem1 didn't succeded");
        Assert.equal(current_quantity, 5, "rem1 wrong quantity");
        Assert.equal(remaining_space, 95, "rem1 wrong remaining space");
        Assert.equal(qty, 10, "rem1 wrong qty");

        (success, current_quantity, remaining_space, qty) = p.remove(10);
        Assert.equal(success, false, "rem2 wrongly succeded");
        Assert.equal(current_quantity, 5, "rem2 wrong quantity");
        Assert.equal(remaining_space, 95, "rem2 wrong remaining space");
        Assert.equal(qty, 10, "rem2 wrong qty");
    }

}

