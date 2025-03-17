const hre = require("hardhat");

async function main() {
  try {
    console.log("Checking Chainlink VRF configuration...");
    
    // Get the deployed contract address
    const raffleAddress = '0x83A8A1CFA58AcA9A8e76B657aD6032EA51D474C5';
    console.log(`Connecting to Raffle contract at: ${raffleAddress}`);
    
    // Get the contract factory and attach to the deployed contract
    const Raffle = await hre.ethers.getContractFactory("Raffle");
    const raffle = Raffle.attach(raffleAddress);
    
    // Get network information
    const network = await hre.ethers.provider.getNetwork();
    console.log(`\nNetwork Information:`);
    console.log(`- Name: ${network.name}`);
    console.log(`- Chain ID: ${network.chainId}`);
    
    // Check if we're on Avalanche
    const isAvalanche = [43113, 43114].includes(network.chainId);
    if (isAvalanche) {
      console.log(`✓ Detected Avalanche network (${network.chainId === 43114 ? 'C-Chain Mainnet' : 'Fuji Testnet'})`);
    }
    
    // Get VRF Coordinator from contract (if possible)
    try {
      // Get the VRF configuration from the contract
      const subscriptionId = await raffle.s_subscriptionId();
      const keyHash = await raffle.s_keyHash();
      const callbackGasLimit = await raffle.callbackGasLimit();
      
      console.log(`\nContract VRF Configuration:`);
      console.log(`- Subscription ID: ${subscriptionId.toString()}`);
      console.log(`- Key Hash: ${keyHash}`);
      console.log(`- Callback Gas Limit: ${callbackGasLimit}`);
      
      // Get expected configuration based on network
      const networkConfig = getVrfInfoForNetwork(network.chainId);
      if (networkConfig) {
        console.log(`\nExpected VRF Configuration for ${networkConfig.network}:`);
        console.log(`- VRF Coordinator: ${networkConfig.coordinator}`);
        console.log(`- Key Hash: ${networkConfig.keyHash}`);
        
        // Check if key hash matches expected for network
        if (keyHash.toLowerCase() !== networkConfig.keyHash.toLowerCase()) {
          console.warn(`⚠️ WARNING: Key hash in contract doesn't match the expected one for this network!`);
          console.warn(`This might cause VRF requests to fail.`);
        } else {
          console.log(`✓ Key hash matches expected value for this network`);
        }
      } else {
        console.log(`\nNo pre-configured VRF information available for network with chainId: ${network.chainId}`);
        if (isAvalanche) {
          console.log(`For Avalanche, please verify your VRF configuration at https://vrf.chain.link`);
        }
      }
      
      // Additional contract parameters relevant to VRF
      const requestConfirmations = 3; // This is hardcoded in your contract
      const numWords = 5; // This is hardcoded in your contract
      
      console.log(`\nOther VRF Parameters:`);
      console.log(`- Request Confirmations: ${requestConfirmations} (hardcoded in contract)`);
      console.log(`- Number of Random Words: ${numWords} (hardcoded in contract)`);
      
      // Check for any pending request
      const requestId = await raffle.s_requestId();
      if (requestId && !requestId.isZero()) {
        console.log(`\nPending VRF Request:`);
        console.log(`- Request ID: ${requestId.toString()}`);
        console.log(`You can check this request on the VRF explorer for your network.`);
      } else {
        console.log(`\nNo pending VRF request found.`);
      }
      
      // Provide guidance based on the network
      console.log(`\n📋 Chainlink VRF Troubleshooting Steps:`);
      console.log(`1. Visit https://vrf.chain.link to manage your subscription`);
      console.log(`2. Ensure your subscription (ID: ${subscriptionId}) is funded with LINK tokens`);
      console.log(`3. Make sure the contract (${raffleAddress}) is added as a consumer to this subscription`);
      console.log(`4. Check that you're using the correct VRF Coordinator address for this network`);
      
      if (networkConfig) {
        console.log(`\nLinks for ${networkConfig.network}:`);
        console.log(`- VRF Dashboard: ${networkConfig.dashboard}`);
        console.log(`- LINK Token: ${networkConfig.linkToken}`);
        console.log(`- Faucets: ${networkConfig.faucets || "N/A"}`);
      }
      
      // Avalanche-specific guidance
      if (isAvalanche) {
        console.log(`\n🔶 Avalanche-specific guidance:`);
        console.log(`- Make sure you have LINK tokens on Avalanche`);
        console.log(`- Ensure your gas parameters are appropriate for Avalanche`);
        
        // Show callback gas limit info for Avalanche
        console.log(`\n⛽ Callback Gas Limit:`);
        console.log(`- Current setting: ${callbackGasLimit}`);
        
        if (callbackGasLimit < 1000000) {
          console.log(`⚠️ Your callback gas limit may be too low for Avalanche.`);
          console.log(`Consider increasing to at least 1,000,000 using updateCallbackGasLimit.js`);
        } else if (callbackGasLimit > 2000000) {
          console.log(`Note: Your callback gas limit is quite high. This will cost more LINK.`);
        } else {
          console.log(`✓ Your callback gas limit is in a good range for Avalanche.`);
        }
        
        // Show key hash options for Avalanche
        if (networkConfig && networkConfig.keyHashOptions) {
          console.log(`\n🔑 Available key hash options for ${networkConfig.network}:`);
          console.log(`- 200 gwei (low cost): ${networkConfig.keyHashOptions["200gwei"]}`);
          console.log(`- 500 gwei (medium cost): ${networkConfig.keyHashOptions["500gwei"]}`);
          console.log(`- 1000 gwei (high cost): ${networkConfig.keyHashOptions["1000gwei"]}`);
          console.log(`\nYou can update your key hash using the updateKeyHash.js script.`);
          console.log(`Higher gwei values generally result in faster VRF response times but cost more LINK.`);
          
          // Check which key hash option is currently being used
          const currentKeyHash = keyHash.toLowerCase();
          let currentOption = "unknown";
          
          if (currentKeyHash === networkConfig.keyHashOptions["200gwei"].toLowerCase()) {
            currentOption = "200 gwei (low cost)";
          } else if (currentKeyHash === networkConfig.keyHashOptions["500gwei"].toLowerCase()) {
            currentOption = "500 gwei (medium cost)";
          } else if (currentKeyHash === networkConfig.keyHashOptions["1000gwei"].toLowerCase()) {
            currentOption = "1000 gwei (high cost)";
          }
          
          console.log(`\nYour contract is currently using the ${currentOption} option.`);
        }
        
        console.log(`- If using Fuji testnet, get test LINK from https://faucets.chain.link/fuji`);
      }
    } catch (error) {
      console.error("Error reading VRF configuration:", error);
    }
  } catch (error) {
    console.error("Script error:", error);
  }
}

// Helper function to get network-specific VRF information
function getVrfInfoForNetwork(chainId) {
  const networks = {
    // Avalanche networks
    43114: {
      network: "Avalanche C-Chain Mainnet",
      coordinator: "0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634",
      keyHash: "0x84213dcadf1f89e4097eb654e3f284d7d5d5bda2bd4748d8b7fada5b3a6eaa0d", // 500 gwei option
      linkToken: "0x5947BB275c521040051D82396192181b413227A3",
      dashboard: "https://vrf.chain.link",
      keyHashOptions: {
        "200gwei": "0xea7f56be19583eeb8255aa79f16d8bd8a64cedf68e42fefee1c9ac5372b1a102",
        "500gwei": "0x84213dcadf1f89e4097eb654e3f284d7d5d5bda2bd4748d8b7fada5b3a6eaa0d",
        "1000gwei": "0xe227ebd10a873dde8e58841197a07b410038e405f1180bd117be6f6557fa491c"
      }
    },
    43113: {
      network: "Avalanche Fuji Testnet",
      coordinator: "0x2eD832Ba664535e5886b75D64C46EB9a228C2610",
      keyHash: "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61",
      linkToken: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846",
      dashboard: "https://vrf.chain.link",
      faucets: "https://faucets.chain.link/fuji",
      keyHashOptions: {
        "200gwei": "0xea7f56be19583eeb8255aa79f16d8bd8a64cedf68e42fefee1c9ac5372b1a102",
        "500gwei": "0x84213dcadf1f89e4097eb654e3f284d7d5d5bda2bd4748d8b7fada5b3a6eaa0d",
        "1000gwei": "0xe227ebd10a873dde8e58841197a07b410038e405f1180bd117be6f6557fa491c"
      }
    },
    // Other networks
    1: {
      network: "Ethereum Mainnet",
      coordinator: "0x271682DEB8C4E0901D1a1550aD2e64D568E69909",
      keyHash: "0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef",
      linkToken: "0x514910771AF9Ca656af840dff83E8264EcF986CA",
      dashboard: "https://vrf.chain.link"
    },
    11155111: {
      network: "Sepolia",
      coordinator: "0x779877A7B0D9E8603169DdbD7836e478b4624789",
      keyHash: "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
      linkToken: "0x779877A7B0D9E8603169DdbD7836e478b4624789",
      dashboard: "https://vrf.chain.link",
      faucets: "https://faucets.chain.link/sepolia"
    },
    137: {
      network: "Polygon Mainnet",
      coordinator: "0xAE975071Be8F8eE67addBC1A82488F1C24858067",
      keyHash: "0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93",
      linkToken: "0xb0897686c545045aFc77CF20eC7A532E3120E0F1",
      dashboard: "https://vrf.chain.link"
    },
    80001: {
      network: "Polygon Mumbai",
      coordinator: "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed",
      keyHash: "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f",
      linkToken: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
      dashboard: "https://vrf.chain.link",
      faucets: "https://faucets.chain.link/mumbai"
    },
    31337: {
      network: "Hardhat Local",
      coordinator: "N/A - Use a mock for testing",
      keyHash: "N/A - Use any bytes32 value for testing",
      linkToken: "N/A - Deploy a mock LINK token",
      dashboard: "N/A - Local testing environment"
    }
  };
  
  return networks[chainId];
}

// Execute the script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
