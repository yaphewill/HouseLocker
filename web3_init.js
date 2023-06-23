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
    var rentAddress = "0x0c6A3c3f8E6CdeAE958a99A3022c86d07D211f47"; //TODO CHANGE IT

    const rent_abi = require("./smart_contracts/Affitto/build/contracts/Affitto.json")

    var contractInstance = new web3.eth.Contract(rent_abi["abi"],rentAddress);

    return contractInstance;

}


function init_verification(){

    var verificationAddress = "0x8FF1898D435483393c087b4F6D5CF8b3159fF5c9"

    const verification_abi = require("./smart_contracts/Affitto/build/contracts/accountVerification.json")

    var contractInstance = new web3.eth.Contract(verification_abi["abi"],verificationAddress);

    return contractInstance;
}

module.exports = {Web3, web3, rentContract, verificationContract};
