var express = require('express');
var router = express.Router();

var {web3,Web3, rentContract} = require("../web3_init");

var {Room} = require ("../mongoose_init")


//STUDENT -------------------------------------------------------------------------------------------------
router.get("/", async (req,res)=>{
    res.render("student/room_explorer")

})



//RENTER --------------------------------------------------------------------------------------------------
router.get("/create",(req,res)=>{
    console.log(req.query.user)
    console.log(req.query.role)
    res.render("renter/room_creation", {user: req.query.user, role:req.query.role})
})

router.post("/create",(req,res)=>{
    console.log(req.body.place)
    console.log(req.body.monthly_fee)
    console.log(req.body.num_beds)
    console.log("renter:",req.body.renter)

    var exp;
    if(req.body.expenses == "on") exp = true;
    else exp = false;
    var min = 1
    var max = 999999999999999999
    var num = Math.floor(Math.random() * 3)
    var rid = Math.floor(Math.random() * (max - min + 1)) + min
    var room1 = new Room({
        id : rid,
        address : req.body.place,
        beds : req.body.num_beds,
        fee : req.body.monthly_fee,
        exp_included : req.body.expenses,
        renter: req.body.renter,
        image:num,
    })
    room1.save();
    res.render("renter/home_renter",{user:req.body.renter, role:"renter", title:"HouseBlocker"})
})

router.get("/get/all", (req,res)=>{
    var r = Room.find({})
    .then(rooms=>{
        console.log(rooms)
        res.send(rooms)
    })
})


module.exports = router;