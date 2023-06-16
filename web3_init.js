const { deploy } = require("truffle-contract/lib/execute");
const { artifacts } = require("truffle")
const fs = require('fs')
const solc = require("solc");

const Web3 = require("web3");
const { type } = require("os");
const web3 = new Web3("http://localhost:7545")


const bankContract = init_contract();


function init_contract(){

    // console.log("a")
    var bankAddress = "0x0930C67a532C65035E8e054b1CD19a7217224818"; //TODO CHANGE IT

    const abi = require("./smart_contracts/bank/build/contracts/Bank.json")


    var contractInstance = new web3.eth.Contract(abi["abi"],bankAddress);
    return contractInstance;

}

module.exports = {Web3, web3, bankContract};
