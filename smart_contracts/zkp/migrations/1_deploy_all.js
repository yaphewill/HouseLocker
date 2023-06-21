var secp = artifacts.require("../contracts/Secp256k1.sol");
var zkp = artifacts.require("../contracts/zkp.sol");
var AccountVerification = artifacts.require("../contracts/accountVerification.sol");



module.exports = async function(deployer){
    await deployer.deploy(secp);
    await deployer.link(secp,zkp);
    await deployer.link(secp,AccountVerification);
    await deployer.deploy(zkp);
    await deployer.deploy(AccountVerification)

};