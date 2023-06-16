var express = require('express');
const { default: Web3 } = require('web3');
var router = express.Router();

var {web3, bankContract} = require("../web3_init");

router.get("/", async (req,res)=>{
    res.render("add")
})

router.post("/", async (req,res)=>{
    // var address1 = "0xA6e32446024b986a42b155497d62433a9e2D321d"
    var address = req.body.address;
    var quantity = req.body.quantity;

    // console.log(address)
    // console.log(quantity)

    bankContract.methods.get_status().call()
    .then(status=>{
        space = status[2]
        console.log("space:",space,"\nquantity:",quantity)
        console.log(space-quantity)
        if((space-quantity)<0){
            res.send("There is not enough space for the quantity.\n Current available space: "+space)
        }
        else{
            bankContract.methods.add(quantity).send({from:address})
            .then(()=>{
                res.send("Operation successfull")
            })
            .catch((err)=>{
                res.send(err)
            })
        }
    })

    // bankContract.methods.add(quantity).send({ from: address })
  })

module.exports = router;