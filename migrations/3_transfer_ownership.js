// migrations/3_transfer_ownership.js
const { admin } = require('@openzeppelin/truffle-upgrades');
 
module.exports = async function (deployer, network) {
  return;
  // Use address of your Gnosis Safe
  const gnosisSafe = '0x5b40fC239134f2d64f8289D56eE47A9AA360c97b';

  // Don't change ProxyAdmin ownership for our test network
  if (network !== 'test') {
    // The owner of the ProxyAdmin can upgrade our contracts
    await admin.transferProxyAdminOwnership(gnosisSafe,{deployer : deployer});
  }
};