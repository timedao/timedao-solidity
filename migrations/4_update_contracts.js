// migrations/4_prepare_upgrade_boxv2.js
//var Box = artifacts.require("./TimeBox.sol")
//var BoxV2 = artifacts.require("./TimeBoxV2.sol")

const { prepareUpgrade } = require('@openzeppelin/truffle-upgrades');
 
module.exports = async function (deployer) {
  return;
  /*const box = await Box.deployed();
  const r = await prepareUpgrade(box.address, BoxV2, { deployer });
  console.log(r);*/
};