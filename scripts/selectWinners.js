const hre = require("hardhat");
const fs = require('fs');

async function main() {
  try {
    console.log("Starting the winner selection process...");
    
    // Get the deployer account
    const [deployer] = await hre.ethers.getSigners();
    console.log(`Using account: ${deployer.address}`);
    
    // Get balance using the correct method in latest ethers version
    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log(`Account balance: ${hre.ethers.formatEther(balance)} ETH\n`);

    // Get the deployed contract address
    const raffleAddress = '0x2e3b71cF183657582F03c44F35fECF235677C1ED';
    console.log(`Connecting to Raffle contract at: ${raffleAddress}`);
    
    // Get the contract factory
    const Raffle = await hre.ethers.getContractFactory("Raffle");
    
    // Connect to the deployed contract
    const raffle = Raffle.attach(raffleAddress);
    console.log("Contract attached successfully");
    
    // Get network info
    const network = await hre.ethers.provider.getNetwork();
    console.log(`Network: ${network.name} (chainId: ${network.chainId})`);
    
    // Check if we're on Avalanche
    const isAvalanche = [43113, 43114].includes(network.chainId);
    if (isAvalanche) {
      console.log(`✓ Detected Avalanche network (${network.chainId === 43114 ? 'C-Chain Mainnet' : 'Fuji Testnet'})`);
    }
    
    // Basic checks with more detailed diagnostics
    try {
      // Step 1: Check ownership
      const owner = await raffle.raffleOwner();
      console.log(`Contract owner: ${owner}`);
      
      if (owner.toLowerCase() !== deployer.address.toLowerCase()) {
        console.error(`Error: Deployer (${deployer.address}) is not the contract owner (${owner})`);
        return;
      }
      console.log("✓ Ownership verified");
      
      // Step 2: Check raffle status
      const raffleEnded = await raffle.raffleEnded();
      if (raffleEnded) {
        console.error("Error: Raffle has already ended.");
        const winners = await raffle.getWinners();
        console.log("Winners already selected:", winners);
        return;
      }
      console.log("✓ Raffle is still active");

      // Step 3: Check user count
      const userCount = await raffle.getVerifiedUsersCount();
      console.log(`Total verified users: ${userCount}`);
      
      if (userCount <= 5) {
        console.error(`Error: Not enough verified users (${userCount}). Need more than 5.`);
        return;
      }
      console.log("✓ Enough users to select winners");
      
      // Step 4: Check VRF configuration
      const subscriptionId = await raffle.s_subscriptionId();
      console.log(`VRF Subscription ID: ${subscriptionId}`);
      
      const keyHash = await raffle.s_keyHash();
      console.log(`VRF Key Hash: ${keyHash}`);
      
      // Check if subscription ID is valid (not zero)
      if (subscriptionId.toString() === '0') {
        console.error("Error: Subscription ID is zero. The contract may not be properly configured for VRF.");
        return;
      }
      console.log("✓ Subscription ID appears valid");
      
      // Avalanche-specific checks and warnings
      if (isAvalanche) {
        console.log("\n🔶 Avalanche-specific information:");
        console.log("- Avalanche uses its own Chainlink VRF coordinators");
        console.log("- Make sure your subscription has enough LINK tokens");
        console.log("- Gas costs on Avalanche differ from other networks");
        
        // Get expected VRF config for Avalanche
        const avalancheConfig = getVrfInfoForNetwork(network.chainId);
        if (avalancheConfig && keyHash.toLowerCase() !== avalancheConfig.keyHash.toLowerCase()) {
          console.warn("⚠️ The key hash in your contract doesn't match the expected one for Avalanche.");
          console.warn(`Expected: ${avalancheConfig.keyHash}`);
          console.warn(`Actual: ${keyHash}`);
        }
      }
      
      console.log("\nAll checks passed. Attempting to select winners...");
      
      // Call selectWinners with appropriate gas settings for Avalanche
      try {
        console.log("\nSubmitting transaction...");
        
        // Avalanche may need different gas settings
        const gasLimit = isAvalanche ? 2000000 : 1500000;
        
        const tx = await raffle.selectWinners({ 
          gasLimit: gasLimit,
        });
        console.log(`Transaction submitted! Hash: ${tx.hash}`);
        
        console.log("Waiting for transaction confirmation...");
        const receipt = await tx.wait();
        console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
        console.log(`Gas used: ${receipt.gasUsed.toString()}`);
        
        // Get requestId
        const requestId = await raffle.s_requestId();
        console.log(`\nChainlink VRF Request ID: ${requestId}`);
        
        console.log("\nIMPORTANT: The winners are not selected immediately.");
        console.log("You need to wait for Chainlink VRF to fulfill the request.");
        console.log("This can take a few minutes to several blocks.");
        console.log("After the request is fulfilled, call 'checkWinners.js' script to see the winners.");
        
      } catch (txError) {
        console.error("\n❌ Transaction failed!");
        
        // Try to get more specific error information
        let reason = "Unknown reason";
        
        if (txError.error && txError.error.message) {
          reason = txError.error.message;
        } else if (txError.message) {
          reason = txError.message;
        }
        
        console.error(`Error reason: ${reason}`);
        
        // Avalanche-specific error handling
        if (isAvalanche) {
          console.log("\n🔶 Avalanche-specific troubleshooting:");
          
          if (reason.includes("execution reverted")) {
            console.log("1. Make sure your Avalanche account has enough AVAX for gas");
            console.log("2. Verify that your VRF subscription on Avalanche is properly funded with LINK");
            console.log("3. Check that the contract is added as a consumer to your Avalanche VRF subscription");
            console.log("4. Try increasing the gas limit further (up to 3000000)");
            
            // Try one more time with max gas limit as a last resort
            if (!reason.includes("tried a second time")) {
              console.log("\nAttempting again with maximum gas limit as last resort...");
              try {
                const lastTx = await raffle.selectWinners({ gasLimit: 3000000 });
                console.log(`Transaction submitted with max gas! Hash: ${lastTx.hash}`);
                console.log("Please check the transaction status on the Avalanche explorer");
                console.log(reason + " (tried a second time)");
              } catch (finalError) {
                console.error("Final attempt also failed:", finalError.message);
              }
            }
          }
        } 
        // More generic error handling
        else if (reason.includes("execution reverted")) {
          console.log("\n🔍 Detailed Diagnostic:");
          
          if (reason.includes("VRF")) {
            console.error("⚠️ VRF request issue detected!");
            console.error("1. Check that your subscription is funded with LINK tokens");
            console.error("2. Ensure this contract is registered as a consumer on your subscription");
            console.error("3. Verify that the VRF Coordinator address is correct for this network");
          } 
          else if (reason.includes("insufficient funds")) {
            console.error("⚠️ Your account doesn't have enough funds to pay for gas");
            const currentBalance = await hre.ethers.provider.getBalance(deployer.address);
            console.error(`Current balance: ${hre.ethers.formatEther(currentBalance)} ETH`);
          }
          else {
            console.error("⚠️ Generic revert. This could be due to:");
            console.error("1. Chainlink VRF subscription issues");
            console.error("2. Contract state preventing the operation");
            console.error("3. Network issues or gas price fluctuations");
          }
        }
      }
    } catch (checkError) {
      console.error("Error during contract checks:", checkError);
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
      keyHash: "0x83250c5584ffa93feb6ee082981c5ebe484c865196750b39835ad4f13780435d",
      linkToken: "0x5947BB275c521040051D82396192181b413227A3"
    },
    43113: {
      network: "Avalanche Fuji Testnet",
      coordinator: "0x2eD832Ba664535e5886b75D64C46EB9a228C2610",
      keyHash: "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61",
      linkToken: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846"
    },
    // Other networks omitted for brevity
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
