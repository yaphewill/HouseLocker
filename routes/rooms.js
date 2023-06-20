var express = require('express');
const { convertToEthersBN } = require('truffle-contract/lib/utils');
var router = express.Router();

var {web3,Web3, rentContract} = require("../web3_init");

router.get("/", async (req,res)=>{
    res.render("rooms_explore")
})


module.exports = router;