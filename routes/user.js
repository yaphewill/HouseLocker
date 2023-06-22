var express = require('express');
const { resource } = require('../app');
var router = express.Router();
const {User} = require("../mongoose_init")
var {web3,verificationContract} = require("../web3_init")
// var {user, role} = require("../global")



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


      var rol = el[0].role;
      console.log("el.role:",rol)
      global.user = addr
      global.role = rol
      // localStorage.setItem("user_global",addr1)
      // localStorage.setItem("role_global",rol);
      if(rol == "student")  res.render("student/home_student", {title:"HouseLocker", user:addr, role:rol})
      else  res.render("renter/home_renter", {title:"HouseLocker", user:addr, role:rol})
      
    }

  })
  .catch((err)=>{
    res.status(500).send(err)
  })
})



router.post("/create", (req,res)=>{
  // console.log(req)
  var addr = req.body.user_address;

  var rol = req.body.role;
  console.log(addr,rol)

  var query = {address:addr}
  User.find(query)
  .then((found)=>{
    console.log(found)
    if(found.length == 0){
      const user1 = new User({address:addr, role:rol})
      user1.save();
      //TODO set global variable
      global.user = addr
      global.role = rol
      if(rol == "student")  res.render("student/home_student", {title:"HouseLocker", user:addr, role:rol})
      else  res.render("renter/home_renter", {title:"HouseLocker", user:addr, role:rol})
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
