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
    var rentAddress = "0xa4aefC6678124f7cA55dd5424b0025F89C03b380"; //TODO CHANGE IT

    const rent_abi = require("./smart_contracts/Affitto/build/contracts/Affitto.json")

    var contractInstance = new web3.eth.Contract(rent_abi["abi"],rentAddress);

    return contractInstance;

}


function init_verification(){

    var verificationAddress = "0x7963dbbE6ee80c7981743e81B0605DE519e6589c"

    const verification_abi = require("./smart_contracts/Affitto/build/contracts/accountVerification.json")

    var contractInstance = new web3.eth.Contract(verification_abi["abi"],verificationAddress);

    return contractInstance;
}

module.exports = {Web3, web3, rentContract, verificationContract};
