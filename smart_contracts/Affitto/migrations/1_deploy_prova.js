var Affitto = artifacts.require("./Affitto.sol");
var accountVerification = artifacts.require("./accountVerification.sol");
var secp = artifacts.require("./Secp256k1.sol");
var zkp = artifacts.require("./zkp.sol")

module.exports = function(deployer){
};


module.exports = async function(deployer){
    await deployer.deploy(secp)
    await deployer.link(secp,zkp)
    await deployer.deploy(zkp)
    // await deployer.link(accountVerification, secp);
    await deployer.link(zkp,accountVerification);
    await deployer.link(secp,accountVerification);
    await deployer.deploy(accountVerification);

    deployer.link(accountVerification,Affitto)
    await deployer.deploy(Affitto);
};