var express = require('express');
const { resource } = require('../app');
var router = express.Router();
const { User } = require("../mongoose_init")
var { web3, verificationContract, rentContract } = require("../web3_init")
// var {user, role} = require("../global")



router.get("/create", async (req, res) => {
	res.render("user_creation")
})



router.get("/login", async (req, res) => {

	var addr = req.query.usr_addr
	var key = req.query.pr_key;
	var query = { address: addr };

	var is_correct = await check_if_correct2(addr, key);
	
	// if (!is_correct){
	// 	res.send("Error: key and address do not match")
	// }

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



// router.post("/create", async (req, res) => {
// 	// console.log(req)
// 	var addr = req.body.user_address;
// 	var key = req.body.key;
// 	var rol = req.body.role;
// 	console.log("ROLE:",rol)

// 	// var rrrr = check_if_correct2(addr,key);
// 	// console.log("prove prima:",rrrr)

// 	var gen = await check_if_correct(addr, key);
	
// 	// if (!is_correct){
// 	// 	res.send("Error: key and address do not match")
// 	// }
// 	console.log(addr, rol)

// 	var query = { address: addr }
// 	User.find(query)
// 		.then((found) => {
// 			if (found.length == 0) {

// 				var r = false;
// 				if(rol=="renter") r=true;
// 				console.log(r,gen[0],gen[1],gen[2],gen[3],gen[4],gen[5])
// 				rentContract.methods.register_user(r,gen[0],gen[1],gen[2],gen[3],gen[4],gen[5],).send({from:addr})
// 				.then(result=>{
// 					console.log("RESSSSS:",result)
// 					const user1 = new User({ address: addr, role: rol })
// 					user1.save();
// 					if (rol == "student") res.render("student/home_student", { title: "HouseLocker", user: addr, role: rol })
// 					else res.render("renter/home_renter", { title: "HouseLocker", user: addr, role: rol })
// 				})
// 				.catch(err=>{
// 					console.log(err)
// 					res.send(err)
// 				})

// 				//TODO set global variable
// 				global.user = addr
// 				global.role = rol
// 			}
// 			else {
// 				res.send("Error: user aready exists")
// 			}
// 		})
// 		.catch((error) => {
// 			res.send(error)
// 		})

// })

router.post("/create", async (req, res) => {
	// console.log(req)
	var addr = req.body.user_address;
	var key = req.body.key;
	var rol = req.body.role;
	console.log("ROLE:",rol)

	var r = false;
	if(rol=="renter") r=true;

	// var is_correct = await check_if_correct2(addr, key);
	// console.log(is_correct)
	// if (!is_correct){
	// 	res.send("Error: key and address do not match")
	// }
	// console.log(addr, rol)

	var query = { address: addr }
	console.log(query)
	User.find(query)
		.then((found) => {
			if (found.length == 0) {

				var r = false;
				if(rol=="renter") r=true;
				console.log(r)
				rentContract.methods.register_user(r).send({from:addr, gas:1000000})
				.then(succ=>{
					console.log(succ)
				})
				const user1 = new User({ address: addr, role: rol })
				user1.save();
				if (rol == "student") res.render("student/home_student", { title: "HouseLocker", user: addr, role: rol })
				else res.render("renter/home_renter", { title: "HouseLocker", user: addr, role: rol })

				//TODO set global variable
				global.user = addr
				global.role = rol
			}
			else {
				res.send("Error: user aready exists")
			}
		})
		// .catch(()=>{
		// 	res.send("errore")
		// })

})

router.get("/remove_me",async (req,res)=>{

	var addr = req.query.address;
	var cid = req.query.cid;
	console.log(addr,cid);

	rentContract.methods.withdraw_from_contract(cid).send({from:addr, gas:1000000})
	.then(result=>{
		console.log(result)
		res.send("success");
	})
	.catch(err=>{
		console.log(err)
		res.send("error")
	})

})


router.get("/i_paid",async(req,res)=>{
	var user = req.query.user;
	var cid = req.query.cid;
	console.log(user,cid);

	rentContract.methods.end_contract_successfully(cid).send({from:user, gas:1000000})
	.then(succ=>{
		console.log(succ);
		res.send(succ);
	})
	.catch(err=>{
		console.log(err);
		res.send(err);
	})
})


module.exports = router;


async function check_if_correct(addr, key) {
	console.log(addr, key)
	return await verificationContract.methods.zkp_accountGen(key).call()
	.then(async (res) => {
		console.log("ress:", res)
		return res;
		// return await verificationContract.methods.zkp_accountVer(res[0], res[1], res[2], res[3], res[4], res[5], addr).call()
		// 	.then(async res => {
		// 		console.log("final res:", res);
		// 		return res;
		// 	})
		// 	.catch(err=>{
		// 		return false;
		// 	})
	})
	.catch(err=>{
		return false;
	})
}


async function check_if_correct2(addr, key) {
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


// router.get("/PROVONI",(req,res)=>{
// 	var addr
// 	rentContract.methods
// })




