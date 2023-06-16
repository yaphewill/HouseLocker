var express = require('express');
const { default: Web3 } = require('web3');
var router = express.Router();

var {web3, bankContract} = require("../web3_init");

router.get("/", async (req,res)=>{
    res.render("remove")
})

router.post("/", async (req,res)=>{
    var address = req.body.address;
    var quantity = req.body.quantity;

    console.log(address)
    console.log(quantity)


    bankContract.methods.remove(quantity).send({from:address})
    .then(data=>{
        res.send(data)
    })
  })

module.exports = router;