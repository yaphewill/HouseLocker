var express = require('express');
const { default: Web3 } = require('web3');
var router = express.Router();

var {web3, rentContract} = require("../web3_init");
var {Hash} = require("../mongoose_init")



router.get('/', async (req, res, next) => {
  res.render('index', { title: 'Express' });
});



router.get("/quantity", async (req,res)=>{
  rentContract.methods.get_quantity().call().then(data=>{
    console.log("quantity:",data)
    res.send(data)
  })
})

router.get("/owner", async (req,res)=>{
  rentContract.methods.get_owner().call().then(data=>{
    console.log("owner:",data)
    res.send(data)
  })
})

router.get("/add_hash_to_db", async (req,res)=>{
  var h = req.query.hash;
  const hash1 = new Hash({hash:h})
  hash1.save()
  .then(res.send("success"))
  .catch("ERRORONEE")
})


router.post("/send_data", (req,res)=>{
  var data1 = req.body.data1;
  var data2 = req.body.data2;

  rentContract.methods.get_data().call({data:data1})
  .then(r=>{
    console.log(r)
    res.send(r)
  })
  // .catch(err=>{
  //   res.send(err)
  // })
})



router.get("/balance", async (req,res)=>{
  var account = req.query.account;
  var {web3} = require("../web3_init");
  web3.eth.getBalance(account, (err, wei)=>{
    var balance = web3.utils.fromWei(wei, 'ether')
    // res.send("<script> alert(balance)</script>")
    res.render("balance_show", {account: account, balance:balance})
  })  
})

router.get("/student/home",(req,res)=>{
  res.render("student/home_student",{title:"HouseLocker", user:"", role:""})
})





//----------------------------------------------------------------------------------------------------------------



module.exports = router;