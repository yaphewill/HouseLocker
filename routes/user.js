var express = require('express');
const { resource } = require('../app');
var router = express.Router();
const { User } = require("../mongoose_init")
var { web3, verificationContract } = require("../web3_init")
// var {user, role} = require("../global")



router.get("/create", async (req, res) => {
	res.render("user_creation")
})



router.get("/login", async (req, res) => {

	var addr = req.query.usr_addr
	var key = req.query.pr_key;
	var query = { address: addr };

	var is_correct = await check_if_correct(addr, key);
	
	if (!is_correct){
		res.send("Error: key and address do not match")
	}

	User.find(query)
		.then(el => {
			// var response;
			if (el.length == 0){
				res.send("user not found")
			} 
			else {
				var rol = el[0].role;
				console.log("el.role:", rol)
				global.user = addr
				global.role = rol
				// localStorage.setItem("user_global",addr1)
				// localStorage.setItem("role_global",rol);
				if (rol == "student") res.render("student/home_student", { title: "HouseLocker", user: addr, role: rol })
				else res.render("renter/home_renter", { title: "HouseLocker", user: addr, role: rol })
			}
		})
		.catch((err) => {
			res.status(500).send(err)
		})
})



router.post("/create", async (req, res) => {
	// console.log(req)
	var addr = req.body.user_address;
	var key = req.body.key;
	console.log(addr,key)
	var rol = req.body.role;

	var is_correct = await check_if_correct(addr, key);
	
	if (!is_correct){
		res.send("Error: key and address do not match")
	}
	console.log(addr, rol)

	var query = { address: addr }
	User.find(query)
		.then((found) => {
			console.log(found)
			if (found.length == 0) {
				const user1 = new User({ address: addr, role: rol })
				user1.save();
				//TODO set global variable
				global.user = addr
				global.role = rol
				if (rol == "student") res.render("student/home_student", { title: "HouseLocker", user: addr, role: rol })
				else res.render("renter/home_renter", { title: "HouseLocker", user: addr, role: rol })
			}
			else {
				res.send("Error: user aready exists")
			}
		})
		.catch((error) => {
			res.send(error)
		})

})

module.exports = router;


async function check_if_correct(addr, key) {
	console.log(addr, key)
	return await verificationContract.methods.zkp_accountGen(key).call()
		.then(async (res) => {
			console.log("ress:", res)
			return await verificationContract.methods.zkp_accountVer(res[0], res[1], res[2], res[3], res[4], res[5], addr).call()
				.then(async res => {
					console.log("final res:", res);
					return res;
				})
				.catch(err=>{
					return false;
				})
		})
		.catch(err=>{
			return false;
		})
}