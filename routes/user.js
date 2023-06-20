var express = require('express');
const { resource } = require('../app');
var router = express.Router();
const {User} = require("../mongoose_init")



router.get("/create", async (req,res)=>{
  res.render("user_creation")
})



router.get("/login",(req,res)=>{
  var addr = req.query.usr_addr
  var query = {address:addr};
  console.log(query)
  User.find(query)
  .then(el=>{
    // var response;
    if(el.length == 0) res.render("index")
    else{
      console.log("el.role:",el[0].role)
      global.user_address = addr;
      global.user_role = el[0].role;
      res.render("home", {title:"HouseLocker", user:"addr", role:el[0].role})
    }

  })
  .catch(()=>{
    res.status(500).send("not found")
  })
})



router.post("/create", (req,res)=>{
  // console.log(req)
  var addr = req.body.user_address;

  var role = req.body.role;
  console.log(addr,role)

  var query = {address:addr}
  User.find(query)
  .then((found)=>{
    console.log(found)
    if(found.length == 0){
      const user1 = new User({address:addr, role:role})
      user1.save();
      //TODO set global variable
      res.render("home",{title:"hello"})
    }
    else{
      res.send("Error: user aready exists")
    }
  })
  .catch(()=>{
    res.send(error)
  })


  // rentContract.methods.create_user(role).send({from:addr}) //TODO uncomment
})

module.exports = router;
