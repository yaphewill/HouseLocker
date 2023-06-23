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
    var rentAddress = "0x3723D0Eb4C9D090199c291C4380A93e18B43b743"; //TODO CHANGE IT

    const rent_abi = require("./smart_contracts/Affitto/build/contracts/Affitto.json")

    var contractInstance = new web3.eth.Contract(rent_abi["abi"],rentAddress);

    return contractInstance;

}


function init_verification(){

    var verificationAddress = "0xFFD8B86c878ACF2035Af712664bDb5A668A1a98e"

    const verification_abi = require("./smart_contracts/Affitto/build/contracts/accountVerification.json")

    var contractInstance = new web3.eth.Contract(verification_abi["abi"],verificationAddress);

    return contractInstance;
}

module.exports = {Web3, web3, rentContract, verificationContract};
