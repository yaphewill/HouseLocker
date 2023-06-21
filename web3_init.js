const { deploy } = require("truffle-contract/lib/execute");
const { artifacts } = require("truffle")
const fs = require('fs')
const solc = require("solc");

const Web3 = require("web3");
const { type } = require("os");
const web3 = new Web3("http://localhost:7545")


const rentContract = init_rent();
const verificationContract = init_verification();


function init_rent(){

    // console.log("a")
    var rentAddress = "0x0930C67a532C65035E8e054b1CD19a7217224818"; //TODO CHANGE IT

    const rent_abi = require("./smart_contracts/Affitto/build/contracts/Affitto.json")

    var contractInstance = new web3.eth.Contract(rent_abi["abi"],rentAddress);

    return contractInstance;

}


function init_verification(){

    var verificationAddress = "0xF25adA16314E689d0f8117704c163A45eF405d3a"

    const verification_abi = require("./smart_contracts/Affitto/build/contracts/Affitto.json")

    var contractInstance = new web3.eth.Contract(verification_abi["abi"],verificationAddress);

    return contractInstance;
}

module.exports = {Web3, web3, rentContract, verificationContract};
