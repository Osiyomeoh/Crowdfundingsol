const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("CrowdfundingModule", (m) => {
  // Deploy the Crowdfunding contract
  const crowdfunding = m.contract("Crowdfunding");

  // Return the deployed contract
  return { crowdfunding };
});
