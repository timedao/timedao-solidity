const { deployProxy , prepareUpgrade} = require('@openzeppelin/truffle-upgrades');
var TimeAtom = artifacts.require("./TimeAtom.sol")

//var simpleERC20 = artifacts.require("./simpleERC20.sol")


module.exports = async function (deployer) { 
  //deployer.deploy(simpleERC20);
  const instance =  await deployProxy(TimeAtom, [], { deployer, initializer: "initialize" });
   



};
