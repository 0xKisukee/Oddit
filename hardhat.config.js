require("@nomicfoundation/hardhat-toolbox");
//require('hardhat-ethernal');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {

  solidity: "0.8.17",

  networks: {

    localhost: {
      url: "http://localhost:8545",
    },

    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/pVoLxyNx_5wl77cX2iFw7s1_EioGnANT",
      accounts: ["2038513449f35cb67eefda892a8080fb324c462ea7ce12784cd2189d10b11b0c"]
    },

  },

  etherscan: {
    apiKey: "7JJITTNG6MBG78BFKZ8IY2SVHGIV2C38H6",
  },

  ethernal: {
    email: "yaname59@gmail.com",
    password: "DarkVador@00@",
    disableSync: false, // If set to true, plugin will not sync blocks & txs
    disableTrace: false, // If set to true, plugin won't trace transaction
    workspace: undefined, // Set the workspace to use, will default to the default workspace (latest one used in the dashboard). It is also possible to set it through the ETHERNAL_WORKSPACE env variable
    uploadAst: true, // If set to true, plugin will upload AST, and you'll be able to use the storage feature (longer sync time though)
    disabled: false, // If set to true, the plugin will be disabled, nohting will be synced, ethernal.push won't do anything either
    resetOnStart: undefined, // Pass a workspace name to reset it automatically when restarting the node, note that if the workspace doesn't exist it won't error
    serverSync: false, // Only available on public explorer plans - If set to true, blocks & txs will be synced by the server. For this to work, your chain needs to be accessible from the internet. Also, trace won't be synced for now when this is enabled.
    skipFirstBlock: false, // If set to true, the first block will be skipped. This is mostly useful to avoid having the first block synced with its tx when starting a mainnet fork
    verbose: false // If set to true, will display this config object on start and the full error object
  }
};
