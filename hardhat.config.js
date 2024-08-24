require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
};
require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
 solidity: "0.8.24",

 networks: {
   sepolia: {
     url: `https://sepolia.infura.io/v3/${process.env.INFURA}`,
     accounts: [process.env.SEPOLIA_PRIVATE_KEY],
   },
 },
 etherscan: {
   apiKey: {
     sepolia: process.env.ETHERSCAN_API_KEY,
   },
 },
};