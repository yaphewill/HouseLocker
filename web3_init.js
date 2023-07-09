const { deploy } = require("truffle-contract/lib/execute");
const { artifacts } = require("truffle")
// const fs = require('fs')
const solc = require("solc");

const Web3 = require("web3");
// const { type } = require("os");
const web3 = new Web3("http://localhost:8545")


const rentContract = init_rent();
const verificationContract = init_verification();


function init_rent(){

    // console.log("a")
    var rentAddress = "0x699B045929498a9c2E0ea0C9539CE0E3b6691B81"; //TODO CHANGE IT

    const rent_abi = require("./smart_contracts/Affitto/build/contracts/Affitto.json")

    var contractInstance = new web3.eth.Contract(rent_abi["abi"],rentAddress);

    return contractInstance;

}


function init_verification(){

    var verificationAddress = "0x68CC80107af901C62D77f06B0C1330CB855C9CFa"

    const verification_abi = require("./smart_contracts/Affitto/build/contracts/accountVerification.json")

    var contractInstance = new web3.eth.Contract(verification_abi["abi"],verificationAddress);

    return contractInstance;
}

module.exports = {Web3, web3, rentContract, verificationContract};
