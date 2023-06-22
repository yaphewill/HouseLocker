var Affitto = artifacts.require("./Affitto.sol");

module.exports = function(deployer){
    deployer.deploy(Affitto);
};