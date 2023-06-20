var express = require('express');
const { convertToEthersBN } = require('truffle-contract/lib/utils');
var router = express.Router();

var {web3,Web3, rentContract} = require("../web3_init");


//STUDENT -------------------------------------------------------------------------------------------------
router.get("/", async (req,res)=>{
    res.render("student/room_explorer")
})



//RENTER --------------------------------------------------------------------------------------------------
router.get("/create",(req,res)=>{
    res.render("renter/room_creation")
})


module.exports = router;